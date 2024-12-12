#!/usr/bin/env perl

use strict;
use warnings;
use v5.16;

use DBI; # DBI & DBD::Pg modules installed using cpan
use Readonly;
use Time::HiRes;
use Time::Piece;
use setup::Def qw(
  %BillingStatus %BillingStatus_Reverse
);

use Setup::DB; 
use Setup::Merchant;
use Setup::myConnect;

my $start_sec = time();
my $tp = gmtime;

# For test purpose define DB connection parameters
my $dbname = 'your_dbname';      # Name of your database
my $host = 'localhost';          # Host where your PostgreSQL server is running
my $port = 5432;                 # Default PostgreSQL port
my $user = 'your_username';      # Database username
my $password = 'your_password';  # Database password
#---------------------------------------------------


# read previous logfile and the current logfile
my @LOGFILES = (
  '/logs/billing-' . $tp->strftime('%Y%m%d'),
  '/logs/billing'
);

# set verbosity from the environment
my $VERBOSE = exists $ENV{VERBOSE} ? $ENV{VERBOSE} // 0 : 0;
my $DEBUG   = exists $ENV{DEBUG}   ? $ENV{DEBUG}        : undef;

if (defined($DEBUG)) {
  if ($VERBOSE < 2) {
    $VERBOSE = 2; # debug mode enables SOME verbosity
  }
  if ($DEBUG ne '/logs/billing') {
    @LOGFILES = ( split /,/, $DEBUG );
  }
}
foreach my $logfile ( @LOGFILES ){
  if (! -f $logfile) {
    Error("Unable to open file '$logfile'");
    exit 1;
  }
}

## May need to authenticate here instead of DB connection:
#Your::Authentication::login_as_root()
#  or die qq{failed to authenticate\n};

###########################################################################
#
# define some constants
#
###########################################################################
 
Readonly::Scalar my $PAYMENT_PROVIDER_ID => 1000;

Readonly::Scalar my $AUTH_PENDING =>
  $BillingStatus{'Auth Pending'};

Readonly::Scalar my $CAPTURE_PENDING =>
  $BillingStatus{'Capture Pending'};

Readonly::Scalar my $REFUND_PENDING =>
  $BillingStatus{'Refund Pending'};

Readonly::Scalar my $VOID_PENDING =>
  $BillingStatus{'Void Pending'};

Readonly::Hash my %reset_status_to => (
  $AUTH_PENDING => $BillingStatus{'New Authorize'},
  $CAPTURE_PENDING   => $BillingStatus{'Authorized'}
);

Readonly::Hash my %cancel_status_to => (
  $AUTH_PENDING => $BillingStatus{'Authorize Failed'},
  $CAPTURE_PENDING   => $BillingStatus{'Capture Failed'}
);

Readonly::Scalar my $email_destination => q{dgaise@gmail.com};

###########################################################################
#
# main logic
#
###########################################################################

my $cycle;
my $batch_file;
my $merchant_name;
my $parent_pid;
my $merchant_id;
my $filename;
my $curr_msg_date;

for my $logfile ( @LOGFILES ) {
  open my $log, '<', $logfile;
  Note("Reading logfile $logfile" . ($DEBUG ? " in DEBUG mode" : ""));

  LOG_FILE_LINE: while (my $line = <$log>) {
    # Parse standard log message to get the fields, i.e.
    # NOTE\t1686788659.01567\tThu Jun 15 00:24:19 2023\billing\t19883\ta8d521127f530bfa4d955fb498d8eb5a0fc18bcf\tMy::Error\t/perl/Error.pm\t1152\tshutting down pid
    my($msg_level, $msg_epoch, $msg_date, $msg_proc, $msg_pid, $msg_eid,
      $msg_module, $msg_file, $msg_line, $message) = split /\t/, $line, 10;

    # save the last msg_date we've seen 
    $curr_msg_date = $msg_date if defined $msg_date;

    # Check Error using a multi-line log message, i.e.
    # ERROR\t1686788658.99963\tThu Jun 15 00:24:18 2023\billing\t19883\ta8d521127f530bfa4d955fb498d8eb5a0fc18bcf\tperl::Message\t/perl/Message.pm\t346\tBad Batch Sent: $VAR1 = bless( {
    #                  'value' => 'Error validating xml data against the schema on line 639  ; lineNumber: 639; columnNumber: 24; the value is not a member of the enumeration.'
    # 
    if ($line =~ /Error validating xml data against the schema on line (\d+)\s+.*the value is not a member of the enumeration/) {
      my $bad_line = $1;
      bad_enumeration(
        $merchant_name, $merchant_id, $batch_file, $bad_line,
        $cycle, $parent_pid, $line, $curr_msg_date
      );
    }

    # from here on out, we only want single-line long messages
    next unless defined $message;

    # look for the start of a processing cycle
    if ($message =~ /
        Begin
        \s+
        (Authorizations|Captures|Refunds|Void cycle) # the void cycle includes
                                                    # the text ' cycle'
        \s+
        for
        \s+
        (merchant .+|MyMerchant) # the void cycle is for all merchants,
                            # so it says 'MyMerchant'
      /x) {

      # we're processing the start of a new merchant, so let's keep track of the
      # cycle, the merchant name, and the parent pid
      $cycle         = $1;
      $merchant_name = $2;
      $parent_pid    = $msg_pid;
    }

    # capture the merchant ID
    elsif ($message =~ /transaction.merchant_id = (\d+)/) {
      $merchant_id = $1;
    }

    elsif ($message =~ /Batch saved to (\S+\.snd)/) {
      $batch_file = $1;
    }

    # capture the filename of the outbound file
    elsif ($message =~ /Unable to open outbound\/(\S+)\.asc/) {
      $filename = $1;
    }

    # look for the error message saying we couldn't download the file
    elsif ($message =~ /Unable to send batch: SFTP File was not found/) {

      # we can only process the file if we saw the merchant and the cycle
      unless (defined $cycle && defined $merchant_name) {
        if (defined $filename) {
          Note(
            "Found 'SFTP File was not found' message for $filename, " .
            "but no cycle or merchant_id was seen; skipping"
          );
        }
        else {
          Note(
            "Found 'SFTP File was not found' message but no filename, " .
            "cycle, or merchant_id was seen; skipping"
          );
        }
        next LOG_FILE_LINE;
      }

      Note(
        "Response file for $cycle $merchant_name under PID $parent_pid " .
        "not found at $msg_date"
      );

      # get a list of transactions that are still pending
      # for this merchant/cycle/pid
      my $transactions = get_transactions_for($merchant_name, $cycle, $parent_pid);

      # if there's no transactions left in a pending state, there's nothing to do
      if (@$transactions == 0) {
        next; # go to next line in log message
      }

      # attempt to download the file; note that if we fail to download it on
      # this particular run of the script, we'll try again the next time the
      # script is run
      download_file($merchant_id, $filename, $cycle);
    }

    # look for the end of a processing cycle
    elsif ($message =~ /
        (Finished|End) # the void cycle says 'End' instead of 'Finished'
        \s+
        (Authorizations|Captures|Refunds|Void cycle) # the void cycle includes
                                                    # the text ' cycle'
        \s+
        for
        \s+
        (merchant .+|MyMerchant) # the void cycle is for all merchants,
                            # so it says 'MyMerchant'
      /x) {

      # we've finished processing the merchant, so let's clear the state
      # variables we've been keeping to track the cycle/merchant/pid
      undef $cycle;
      undef $merchant_name;
      undef $parent_pid;
    }
  } # while $line = <$log>
}

# write a message to STDOUT saying how long we ran
say "PROCESSING COMPLETE in " . sec2dhms(time() - $start_sec);

exit;

###########################################################################
#
# get the transactions being processed for the given merchant under the
# given pid; we need the cycle because, for some reason, we don't separate
# out voids by merchant
#
###########################################################################

sub get_transactions_for {
  my ($merchant_name, $cycle, $pid) = @_;
  $merchant_name =~ s/^merchant\s+//; # trim 'merchant from the beginning'
  my $sql = <<SQL;
SELECT t.id
  FROM transaction AS t
  INNER JOIN latest_transaction_detail AS ltd ON ltd.transaction_id = t.id
  INNER JOIN transaction_detail        AS td  ON td.id = ltd.transaction_detail_id
 WHERE td.payment_provider_id = $PAYMENT_PROVIDER_ID
   AND t.pid = $pid
SQL

  # for some reason, we don't separate out voids by merchant
  if ($cycle eq 'Void') {
    $sql .= <<SQL;
   AND t.billing_status_id = $VOID_PENDING
SQL
  }
  else {
    my $mid = get_merchant_id($merchant_name);
    $sql .= <<SQL;
   AND t.billing_status_id IN ($AUTH_PENDING, $CAPTURE_PENDING, $REFUND_PENDING)
   AND t.merchant_id = $mid
SQL
  }
  chomp $sql; # there's a newline we don't need

  if ($VERBOSE < 2) {
    Note("Counting $cycle transactions for $merchant_name under PID $pid");
  }
  else {
    Note("Counting $cycle transactions for $merchant_name under PID $pid using\n$sql");
  }
  my $transactions = Setup::DB::query_read($sql, []);
  $transactions = [ # flatten the array to just the transaction IDs
    map { $_->[0] } @$transactions
  ];
  Note(scalar(@$transactions) . " transactions found");
  return $transactions;
}

###########################################################################
#
# subroutine to download the file and process it
#
###########################################################################

sub download_file {
  my($mid, $file_name, $cycle) = @_;
  my $merchant_obj = Setup::Merchant->new();

  my $connection = Setup::myConnect->new(sftp => 1);

  my $returnResponse;
  if ($cycle eq 'Void') {
    Note("Attempting to fetch void cycle file $file_name");
    $returnResponse = $connection->_get_sftp_batch($file_name, undef);
  }
  else {
    my $mid = get_merchant_id($merchant_name);

    unless ($merchant_obj->load_by_id($mid)) {
      Error("Unable to load merchant '$merchant_name' from mid $mid");
      return;
    }

    Note("Attempting to fetch file $file_name for merchant $merchant_name");

    my $tokenized_pm = $merchant_obj &&
      $merchant_obj->get_named_value('tokenizedPaymentMethods');

    $returnResponse =
      $connection->_get_sftp_batch($file_name,$tokenized_pm);
  }

  if (defined($returnResponse) and $returnResponse->{tag_ok} eq 1 ) {
    Note("File $file_name successfully fetched");
  }
  else {
    Note("Unable to fetch file $file_name! ".
         "This will have to be processed later...");
    return;
  }

  if ($DEBUG) {
    Note("not processing $file_name due to DEBUG mode");
  }
  else {
    Note("starting to process $file_name");

    Note("finished processing $file_name");
  }
}

###########################################################################
#
# subroutine to examine a file with the error "the value is not a member
# of the enumeration"
#
###########################################################################

sub bad_enumeration {
  my ($merchant_name, $merchant_id, $batch_file, $bad_line,
      $cycle, $parent_pid, $message, $msg_date) = @_;

  # strip away the D::D from the message
  ($message) = $message =~ /.*'value' => '(.*)'\s*\Z/;
  Note(
    "Encountered '$message' for $merchant_name at $msg_date; investigating..."
  );

  # first, let's read the file and pull out information
  open my $in, '<', $batch_file
    or die "Unable to open $batch_file: $!";
  my @transactions;
  my ($current_transaction, @current_txn_xml, $current_txn_start,
      $bad_transaction, $bad_transaction_xml, $bad_transaction_status,
      $bad_transaction_disp);
  while (my $line = <$in>) {
    push @current_txn_xml, $line;

    # recognize the start of a transaction
    # sale_id for auth cycle, authorization id for void, credit id for refund and capture id for partial
    if ($line =~ /<sale id="([^"]+)"/          || 
        $line =~ /<authorization id="([^"]+)"/ ||
        $line =~ /<credit id="([^"]+)"/        ||
        $line =~ /<capture id="([^"]+)"/ ) {
      push @transactions, $1;
      $current_transaction = $1;
      @current_txn_xml = ($line); # clear our prior transaction
      $current_txn_start = $.; # $. is current line# in file being read
    }

    # capture the transaction where the error occurs
    elsif ($. == $bad_line) {
      $bad_transaction = $current_transaction;

      # check to see if the transaction is still pending
      ($bad_transaction_status, $bad_transaction_disp) =
        merchant_transaction_status(
          $bad_transaction, $parent_pid, $merchant_id
        );

      # if it's not, then we're done

      if (! defined $bad_transaction_status ||
          ( $bad_transaction_status != $AUTH_PENDING &&
            $bad_transaction_status != $CAPTURE_PENDING &&
            $bad_transaction_status != $REFUND_PENDING )
      ) {
        Note(
          "Bad transaction $bad_transaction " .
          status_display($bad_transaction_status) . " and " .
          disposition_display($bad_transaction_disp) . 
          "; finished investigating"
        );
        return;
      }
    }
    elsif ($line =~ m{</sale>} && $bad_transaction &&
           $bad_transaction eq $current_transaction) {
      # redact any sensitive information from the transaction
      #
      # we aren't including country or state in this because they are
      # enumerated fields and may be the source of the error
      my $sensitive_fields = join '|', qw(
        password
        firstName middleInitial lastName name
        addressLine\d+ city zip 
        Token expDate cardValidationNum
      );
      my $count = 0;
      foreach my $xline (@current_txn_xml) {
        $xline =~ s{<($sensitive_fields)>[^<]+</\1>}{<$1>**REDACTED**</$1>};

        # re-build XML with line numbers
        $bad_transaction_xml .=
          sprintf '%5d: %s', $current_txn_start + $count++, $xline;
      }
    }
  } # while <$in>
  close $in;

  if ($bad_transaction) {
    # Because the transaction failed because of configuration problems,
    # compose an email to send to TST so they can open a ticket with CTS
    my $subject = qq{Encountered '$message' for $merchant_name at $msg_date};
    my $email_message = $subject . "\n\n";
    $email_message .= qq{Offending XML:\n$bad_transaction_xml\n\n};

    # now add what we're doing to fix the problem to this message
    $email_message .= $DEBUG ? qq{Proposed Solution:} : qq{Solution:};

    my $reset_status = $reset_status_to{$bad_transaction_status};
    my $cancel_status = $cancel_status_to{$bad_transaction_status};
    my $sql = qq{UPDATE transaction SET billing_status_id = $cancel_status}
            . qq{ WHERE billing_status_id = $bad_transaction_status}
            . qq{ AND pid = $parent_pid}
            . qq{ AND merchant_tx_identifier = '$bad_transaction'};
    $email_message .= $DEBUG
             ? qq{\n/tst/scripts/runSql.pl --sql="$sql" --verbose --mode 0}
             : "\n$sql";

    if ($DEBUG) {
        $sql = qq{UPDATE transaction SET billing_status_id = $reset_status}
             . qq{ WHERE billing_status_id = $bad_transaction_status}
             . qq{ AND pid = $parent_pid}
             . qq{ AND NOT merchant_tx_identifier = '$bad_transaction'};
        $email_message .= qq{\n/tst/scripts/runSql.pl --sql="$sql" --verbose --mode 0};
    }
    else {
        my $committed = 0; # let's report the number of committed records all at once

        my $rc = Setup::DB::query($sql);
        if (!defined $rc or $rc eq "0E0") {
            $email_message .= "\nERROR: No records found for requested sql";
            Error("No records found for requested sql");
            Setup::DB::rollback();
        }
        else {
            $committed = $rc; # count the record we updated
            $email_message .= "\n$rc records updated";

            # first, count if there are other transactions affected
            $sql = qq{SELECT COUNT(*) from transaction}
                . qq{ WHERE billing_status_id = $bad_transaction_status}
                . qq{ AND pid = $parent_pid}
                . qq{ AND NOT merchant_tx_identifier = '$bad_transaction'};
            my $count = Setup::DB::query_read_only($sql, []);

            # if there are transactions affected, reset them
            if ($count->[0]->[0] > 0) {
                $sql = qq{UPDATE transaction SET billing_status_id = $reset_status}
                    . qq{ WHERE billing_status_id = $bad_transaction_status}
                    . qq{ AND pid = $parent_pid}
                    . qq{ AND NOT merchant_tx_identifier = '$bad_transaction'};
                $email_message .= "\n$sql";

                $rc = Setup::DB::query($sql);
                if (!defined $rc or $rc eq "0E0") {
                    $email_message .= "\nERROR: No records found for requested sql";
                    Error("No records found for requested sql");
                    Setup::DB::rollback();
                }
                else {
                  $committed += $rc; # count the records we updated
                  $email_message .= "\n$rc records updated";
                }
            }
        }

        Setup::DB::commit();
        Note("Committed - Number of updated records is $committed");
    }

    # log what we did in a note
    Note($email_message);

    # now send the email saying what was wrong and what we did
    open my $out, qq{| mailx -s "$subject" "$email_destination" };
    say {$out} $email_message;
    close $out;
  }
}

sub status_display {
  my $status_id = shift;
  if (! defined $status_id) {
    return "has a billing_status_id of NULL";
  }
  my $status_str = $BillingStatus_Reverse{$status_id}; 
  return "in status $status_str ($status_id)"
}

sub disposition_display {
  my $disp_id = shift;
  if (! defined $disp_id) {
    return "has a current_disposition_id of NULL";
  }
  my $disp_str = "TBD"; 
  return "has a disposition of $disp_str ($disp_id)";
}

sub merchant_transaction_status {
  my ($bad_transaction, $pid, $mid) = @_;
  Note("Checking current status of transaction $bad_transaction");

  my $sql = <<SQL;
SELECT t.billing_status_id, t.current_disposition_id
  FROM transaction AS t
  INNER JOIN latest_transaction_detail AS ltd ON ltd.transaction_id = t.id
  INNER JOIN transaction_detail        AS td  ON td.id = ltd.transaction_detail_id
 WHERE td.payment_provider_id = $PAYMENT_PROVIDER_ID
   AND t.merchant_tx_identifier = '$bad_transaction' and t.current_merchant_ts > now() - interval '2 days'
SQL
  chomp $sql; # there's a newline we don't need

  NoteVerbose(
    "executing the following SQL:\n$sql"
  );

  my $transactions = Setup::DB::query_read_only($sql, []);

  NoteVerbose(
    "received the following results:\n" .
    SafeDD($transactions)
  );

  # return the status id and the disposition id
  return ($transactions->[0]->[0], $transactions->[0]->[1]);
}

###########################################################################
#
# subroutine to get the merchant_id from the merchant name
#
###########################################################################

sub get_merchant_id {
  my($merchant_name) = @_;
  $merchant_name =~ s/^merchant\s+//; # trim 'merchant from the beginning'
  state $merchant_id = {};

  if (! exists $merchant_id->{$merchant_name}) {
    my $sql = qq{SELECT m.id FROM merchant AS m WHERE m.name = ?};
    my $rows = Setup::DB::query_read_only($sql, [ { 'type' => 'merchant.name', 'value' => $merchant_name } ]);
    if (@{ $rows } > 1) {
      Error("More than one row returned for SQL:\n$sql");
      return;
    }
    $merchant_id->{$merchant_name} = $rows->[0]->[0];
  }
  return $merchant_id->{$merchant_name};
}

###########################################################################
#
# Functions to log 
#
###########################################################################

sub Note {
  my $msg = shift;
  my $verbosity = shift // 1;
  say "NOTE: $msg" if $VERBOSE >= $verbosity;
}

sub NoteVerbose {
  my $msg = shift;
  my $verbosity = shift // 2;
  say "NOTE_VERBOSE: $msg" if $VERBOSE >= $verbosity;
}

sub Error {
  my $msg = shift;
  say "ERROR: $msg";
}

###########################################################################
#
# given a number of seconds, output the duration in "Nd Nh Nm Ns" format
#
###########################################################################

sub sec2dhms {
    my $seconds = shift;
    my $orig_sec = $seconds;
    my @dhms;
    if (my $days = int($seconds / 86400)) {
        push @dhms, sprintf '%dd', $days; $seconds -= $days * 86400;
    }
    if (my $hours = int($seconds / 3600)) {
        push @dhms, sprintf '%dh', $hours; $seconds -= $hours * 3600;
    }
    if (my $minutes = int($seconds / 60)) {
        push @dhms, sprintf '%dm', $minutes; $seconds -= $minutes * 60;
    }
    if ($orig_sec > 10) {
      # if it took longer than 10 seconds, don't bother with fractional seconds
      $seconds = int($seconds);
      if ($seconds) {
          push @dhms, sprintf '%ds', $seconds;
      }
    }
    else {
      push @dhms, sprintf '%0.3fs', $seconds;
    }
    return join q{ }, @dhms;
}

__END__

=head1 NAME

batch_processing.pl - post-process batches

=head1 SYNOPSIS

This script has no parameters, because it it meant to be run through 
Rundeck, but it does check two environment variables:

=over 4

=item B<VERBOSE>

=over

=item VERBOSE=0 (default)

Display only Error-level messages and the final "PROCESSING COMPLETE" 
message on stdout.

=item VERBOSE=1 

In addition to the messages from VERBOSE=0, displays on stdout Note messages
about changes being made to transactions.

=item VERBOSE=2

In addition to the messages from VERBOSE=1, displays all Note messages on 
stdout.

=back

=item B<DEBUG>

When defined, this variable points to a log file to read in debug mode.
This mode prevents the script from making changes to the database, and
allows the script to be run on historical log files to demonstrate what
actions it would take.

=back

=head1 DESCRIPTION

On a semi-regular basis, PP fails to return a response file in the amount
of time we allot to it.  Rather than increase the time we wait for the file
indefinitely, we should create a Rundeck job that runs hourly that checks to
see if response files that we stopped waiting for are now available for
processing.

=cut
