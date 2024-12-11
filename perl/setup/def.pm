#!/usr/bin/env perl

# ~/perl/setup/def.pm

package Setup::Def;  # Define the package

use strict;
use warnings;

# Define the %BRD_BillingStatus hash
our %BillingStatus = (
    'Unknown'         => 0,
    'New'             => 1,  
    'Auth Pending'    => 2, 
    'Authorized'      => 3,
    'Capture Pending' => 4,
    'Captured'        => 5,
    'Refund Pending'  => 6,
    'Refunded'        => 7,
    'Refund Error'    => 8,
    'Rejected'        => 9,
    'Void Pending'    => 10,
    'Void'            => 11,
);

# Define the reverse lookup hash %BillingStatus_Reverse
our %BillingStatus_Reverse = reverse %BRD_BillingStatus;

1;
