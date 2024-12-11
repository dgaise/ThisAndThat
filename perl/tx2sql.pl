#!/usr/bin/env perl

use strict;
use warnings;
use v5.12;

use Getopt::Long;
use List::MoreUtils qw(uniq);
use Pod::Usage;
use POSIX qw( strftime );
use Text::Wrap;

my $in_type;
my $out_type;
my $column;
my $uniq = 1;
my $help = 0;
my $man  = 0;
GetOptions(
  'in=s'     => \$in_type,
  'out=s'    => \$out_type,
  'column=s' => \$column,
  'uniq!'    => \$uniq,
  'help|?'   => \$help,
  'man'      => \$man
) or pod2usage(2);
pod2usage(-sections => [qw(SYNOPSIS)]) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

$in_type //= 'email';

my %columns = (
  'tid'      => 2,
  'rid'      => 3,
  'tpid'     => 8,
  'rpid'     => 9,
  'autobill' => 13
);
# if $column is defined, not a number, and exists in the %columns hash,
# use %columns to translate the stringy label to a column number
if (defined $column && ! $column =~ /^\d+$/ && exists $columns{$column}) {
  $column = $columns{$column};
}

###########################################################################
#
# process input from paste buffer
#
###########################################################################

my %in_processors = (
  'email' => sub {
    my($line, $txn, $ref) = @_;
    if ($line =~ /Transaction ID: (\d+)/) {
      push @$txn, $1;
    }
    elsif ($line =~ /Refund ID: (\d+)/) {
      push @$ref, $1;
    }
    $out_type //= 'status';
  },
  'query' => sub {
    my($line, $txn, $ref) = @_;
    my @col = split /\s*\|\s*/, $line;
    $column //= $columns{tid}; # if $column isn't defined, default to transaction id column
    push @$txn, $col[$column];
  }
);
my @transactions;
my @refunds;
if (exists $in_processors{$in_type}) {
  open my $pb_in, "pbpaste |";
  while (my $line = <$pb_in>) {
    $in_processors{$in_type}->($line, \@transactions, \@refunds);
  }
  close $pb_in;
}
else {
  die "Unknown input value '$in_type'; known values are:\n  * "
    . join("\n  * ", keys %in_processors)."\n";
}
# get rid of undefined transaction numbers
while (scalar(@transactions) > 0 && !defined($transactions[0])) {
  shift @transactions;
}
if ($uniq && @transactions) {
  @transactions = uniq @transactions;
}
while (scalar(@refunds) > 0 && !defined($refunds[0])) {
  shift @refunds;
}
if ($uniq && @refunds) {
  @refunds = uniq @refunds;
}

printf "%d transactions / %d refunds extracted from paste buffer\n",
  scalar(@transactions), scalar(@refunds);

exit if scalar(@transactions) == 0 && scalar(@refunds) == 0;

###########################################################################
#
# process ouput to paste buffer
#
###########################################################################

my %out_processors = (
  'status' => sub {
    my @SQL;
    if (@transactions) {
      my $tx_list = join(", ", @transactions);
      $Text::Wrap::columns = 80;
      $tx_list = wrap(" "x11, " "x11, $tx_list);
      push @SQL, trim_prefix(qq{      SELECT pp.name || ' (' || pp.id || ')' AS name,
             m.name merchant, t.division_number,
             t.id AS "t.id",
             t.merchant_tx_identifier AS tx_identifier,
             length(t.auth_response) AS auth_resp_len,
             e.created,
             t.pid AS "t.pid",
             t.current_disposition_id || ' (' || tdt.description || ')' AS cur_disp_id,
             t.brd_billing_status_id  || ' (' || bbs.description || ')' AS brd_billing_status_id,
             t.online_auth,
             t.autobill_id,
             t.to_be_captured AS "2bCap",
             pm.tokenized AS tkn
          FROM transaction               AS t
          JOIN entity                    AS e   ON e.id = t.entity_id
          JOIN latest_transaction_detail AS ltd ON ltd.transaction_id = t.id
          JOIN transaction_detail        AS td  ON ltd.transaction_detail_id = td.id
          JOIN payment_provider          AS pp  ON td.payment_provider_id = pp.id
          LEFT JOIN brd_billing_status   AS bbs ON t.brd_billing_status_id = bbs.id
          LEFT JOIN tx_disposition_type  AS tdt ON t.current_disposition_id = tdt.id
          LEFT JOIN autobill             AS ab  ON t.autobill_id=ab.id
          LEFT JOIN payment_method       AS pm  ON pm.id=ab.payment_method_id
          LEFT JOIN merchant             AS m   ON m.id=t.merchant_id      
         WHERE t.id IN ($tx_list)
           AND COALESCE(t.brd_billing_status_id, 0) NOT IN (0,2)});
    }
    if (@refunds) {
      my $tx_list = join(", ", @refunds);
      $Text::Wrap::columns = 80;
      $tx_list = wrap(" "x11, " "x11, $tx_list);
      push @SQL, trim_prefix(qq{      SELECT pp.name || ' (' || pp.id || ')' AS name,
            'Refund' AS "Type",
             t.id AS "t.id",
             r.id AS "r.id",
             t.merchant_tx_identifier AS tx_identifier,
             length(t.auth_response) AS auth_resp_len,
             e.created,
             t.pid AS "t.pid",
             r.pid AS "r.pid",
             r.refund_status_id       || ' (' || rs.status || ')' AS refund_status_id,
             t.current_disposition_id || ' (' || tdt.description || ')' AS cur_disp_id,
             t.brd_billing_status_id  || ' (' || bbs.description || ')' AS brd_billing_status_id
        FROM refund                    AS r
        JOIN transaction               AS t   ON t.id = r.transaction_id
        JOIN entity                    AS e   ON e.id = t.entity_id
        JOIN latest_transaction_detail AS ltd ON ltd.transaction_id = t.id
        JOIN transaction_detail        AS td  ON ltd.transaction_detail_id = td.id
        JOIN payment_provider          AS pp  ON td.payment_provider_id = pp.id
        LEFT JOIN brd_billing_status   AS bbs ON t.brd_billing_status_id = bbs.id
        LEFT JOIN tx_disposition_type  AS tdt ON t.current_disposition_id = tdt.id
        LEFT JOIN refund_status        AS rs  ON r.refund_status_id = rs.id
        LEFT JOIN autobill             AS ab  ON t.autobill_id=ab.id
        LEFT JOIN payment_method       AS pm  ON pm.id=ab.payment_method_id
       WHERE r.id IN ($tx_list)});
    }
    return join("\n;\n", @SQL)."\n ORDER BY 1,2,3;\n";
  },
  'refund' => sub {
    my $tx_list = join(", ", @refunds);
    $Text::Wrap::columns = 80;
    $tx_list = wrap(" "x11, " "x11, $tx_list);
    return trim_prefix(qq{    SELECT pp.name || ' (' || pp.id || ')' AS name,
           t.id AS "t.id",
           r.id AS "r.id",
           t.merchant_tx_identifier AS tx_identifier,
           length(t.auth_response) AS auth_resp_len,
           t.current_merchant_ts,
           e.created,
           t.current_disposition_id as cur_disp_id,
           t.pid AS "t.pid",
           r.pid AS "r.pid",
           r.refund_status_id       || ' (' || rs.status || ')' AS refund_status_id,
           t.current_disposition_id || ' (' || tdt.description || ')' AS cur_disp_id,
           t.brd_billing_status_id  || ' (' || bbs.description || ')' AS brd_billing_status_id,
           t.online_auth,
           t.autobill_id,
           t.to_be_captured as "2bCap",
           pm.tokenized as tkn
      FROM refund                    AS r
      JOIN transaction               AS t   ON t.id = r.transaction_id
      JOIN entity                    AS e   ON e.id = t.entity_id
      JOIN latest_transaction_detail AS ltd ON ltd.transaction_id = t.id
      JOIN transaction_detail        AS td  ON ltd.transaction_detail_id = td.id
      JOIN payment_provider          AS pp  ON td.payment_provider_id = pp.id
      LEFT JOIN brd_billing_status   AS bbs ON t.brd_billing_status_id = bbs.id
      LEFT JOIN tx_disposition_type  AS tdt ON t.current_disposition_id  = tdt.id
      LEFT JOIN refund_status        AS rs  ON r.refund_status_id = rs.id
      LEFT JOIN autobill             AS ab  ON t.autobill_id=ab.id
      LEFT JOIN payment_method       AS pm  ON pm.id=ab.payment_method_id
     WHERE r.id IN ($tx_list)
     ORDER BY 1,2;\n});
  },
  'count' => sub {
    my $tx_list = join(", ", @transactions);
    $Text::Wrap::columns = 80;
    $tx_list = wrap(" "x11, " "x11, $tx_list);
    return trim_prefix(qq{      SELECT pp.name || ' (' || pp.id || ')' as name,
             t.current_disposition_id || ' (' || tdt.description || ')' AS cur_disp_id,
             t.brd_billing_status_id || ' (' || bbs.description || ')' as brd_billing_status_id,
             CASE WHEN length(t.auth_response) > 3000 THEN '>3000' ELSE '' END as auth_resp_len,
             COUNT(t.id) AS count
        FROM transaction               AS t
        JOIN entity                    AS e   ON e.id = t.entity_id
        JOIN latest_transaction_detail AS ltd ON ltd.transaction_id = t.id
        JOIN transaction_detail        AS td  ON ltd.transaction_detail_id = td.id
        JOIN payment_provider          AS pp  ON td.payment_provider_id = pp.id
        LEFT JOIN brd_billing_status   AS bbs ON t.brd_billing_status_id = bbs.id
        LEFT JOIN tx_disposition_type  AS tdt ON t.current_disposition_id = tdt.id
        LEFT JOIN autobill             AS ab  ON t.autobill_id=ab.id
        LEFT JOIN payment_method       AS pm  ON pm.id=ab.payment_method_id
       WHERE t.id IN ($tx_list)
       GROUP BY 1, 2, 3, 4
       ORDER BY 1, 2, 3;\n});
  },
  'uuid' => sub {
    my $like_list = join "\n    OR ", map { "item_ids like '%$_%'" } @transactions;
    return "SELECT uuid, item_count FROM bims_batch_log\n WHERE $like_list";
  },
  'gearman' => sub {
    my $tx_list = join("|", @transactions);
    my $ds = strftime(q{%Y%m%d}, localtime());
    return qq{cd /var/vindicia/logs;egrep '$tx_list' gearman_workerd.PollBIMS.json-$ds gearman_workerd.PollBIMS.json | }
         . qq{grep 'RC:' | }
         .  q{perl -MJSON -nE 'my $json = decode_json $_; say $json->{ts} . ": " . $json->{msg};'};
  },
  'authfail' => sub {
    my $tx_list = join(",", @transactions);
    return qq{/tst/scripts/runSql.pl --sql="UPDATE transaction }
         . qq{SET brd_billing_status_id = 3 WHERE brd_billing_status_id = 4 }
         . qq{AND id IN ($tx_list)" --mode=0};
  },
  'comma' => sub {
    return join(",", @transactions, @refunds)
  },
  'pipe' => sub {
    return join("|", @transactions, @refunds)
  },
  'none' => sub {
    return join(" ", @transactions, @refunds)},
);

if (exists $out_processors{$out_type}) {
  to_pb($out_processors{$out_type}->());
}
else {
  die "Unknown output value '$out_type'; known values are:\n  * "
    . join("\n  * ", keys %out_processors)."\n";
}

sub to_pb {
  my $text = shift;
  open my $pb_out, "| pbcopy";
  print {$pb_out} $text;
  close $pb_out;
}

sub trim_prefix {
  my ($str) = @_;
  my ($prefix) = $str =~ /^(\s+)/;
  return join "\n", map { s/^$prefix//; $_ } split /\n/, $str;
}

__END__

=head1 NAME

tx2sql - transform transactions in the paste buffer into SQL queries

=head1 SYNOPSIS

tx2sql [options]

 Options:
   --in              format of the contents of the paste buffer;
                     valid values are 'email' and 'query'; the default
                     is 'email'.
   --column          for input type 'query', which column to cut
   --out             query to output to the paste buffer; valid values
                     are 'status', 'uuid', 'gearman', 'comma', and 'none';
                     the default is 'status'.
   --help            brief help message
   --man             full documentation

=head1 OPTIONS

=over 8

=item B<--in>

This script processes two formats of paste buffer input: the entire
body of a root "NNN Pending Transactions Found In <server>" email (type
`email`), or copied rows from a query that outputs transaction IDs as
the third tabular column (type `query`), like so:

     pp.id |  name  |     id     | tx_identifier | ...
    -------+--------+------------+---------------+ ...
      1073 | Payway | NNNNNNNNNN | xxxxxxxxxxx   | ...

=item B<--column>

If the input type is 'query', you can specify which column to grab, either
numerically, or by the header values 'tid' (transaction ID), 'rid' (refund ID),
'tpid' (transaction pid), 'rpid' (refund pid), or 'autobill'.

=item B<--out>

This script produces two different SQL queries: status or uuid. If the input
type was `email`, the output type is assumed to be `status`, which produces
a SQL query to look in the transaction table to determine the status of the
listed transactions.

If the input type was `query`, the output type is assumed to be `uuid`, which
produces a SQL query to look in the bims_batch_log table for item_ids like
the listed transactions.

If the output type is 'gearman', the output is a grep command for finding
transactions in the gearman_workerd.PollBIMS.json logs.

If the output type is 'authfail', the output is a runSql command for converting
transactions from Auth Pending to Auth Failed.

If the output type is 'comma', the output is a comma-separated list of
transactions.

If the output type is 'none', the output is a space-separated list of
transactions.

=item B<--help>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<tx2sql> will read the Mac paste buffer, transform the text into a list of
transaction IDs, and then push a SQL query based on those IDs back to the
paste buffer.

=cut

