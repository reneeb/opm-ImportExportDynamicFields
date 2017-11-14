#!/usr/bin/perl

# --
# bin/ps.ImportExportDynamicFields.pl - import/export dynamic fields
# Copyright (C) 2017 Perl-Services.de, http://perl-services.de
# --
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU AFFERO General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# or see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;

use File::Basename;
use FindBin qw($RealBin);
use lib dirname($RealBin);

use vars qw (%opts);
use Getopt::Long;
GetOptions(
    'name=s' => \$opts{name},
    'file=s' => \$opts{file},
);

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::Main;
use Kernel::System::DB;
use Kernel::System::CSV;
use Kernel::System::DynamicField;

# create common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = Kernel::Config->new(%CommonObject);
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-ps.ImportExportDynamicFields.pl',
    %CommonObject,
);
$CommonObject{TimeObject}         = Kernel::System::Time->new(%CommonObject);
$CommonObject{MainObject}         = Kernel::System::Main->new(%CommonObject);
$CommonObject{DBObject}           = Kernel::System::DB->new(%CommonObject);
$CommonObject{CSVObject}          = Kernel::System::CSV->new(%CommonObject);
$CommonObject{DynamicFieldObject} = Kernel::System::DynamicField->new( %CommonObject );

if (
    !$opts{file} || !-f $opts{file} || !$opts{name}
) {
    print STDERR qq~$0 [-name <name>] [-file <file> ]

name    dynamic field name
file    CSV file that contains the values

Example:

  $0 --name Categories --file categories.csv

Imports the values for the dynamic field I<Categories>. When key and value
are identical, you can use one value per line in the CSV file. If key and
value are different, it should look like

  "key1";"value1"
  "key2";"value2"

~;

    exit 1;
}

my $ContentRef = $CommonObject{MainObject}->FileRead(
    Location => $opts{file},
);

my $Values = $CommonObject{CSVObject}->CSV2Array(
    String => ${$ContentRef},
);

my %PossibleValues;
for my $Row ( @{ $Values || [] } ) {
    my ($Key, $Value) = @{ $Row || [] };

    $Value = $Key if !defined $Value;

    $PossibleValues{$Key} = $Value;
}

my $DynamicField = $CommonObject{DynamicFieldObject}->DynamicFieldGet( Name => $opts{name} );

if ( $DynamicField->{FieldType} ne 'Dropdown' and $DynamicField->{FieldType} ne 'Multiselect' ) {
    print STDERR "This feature is only available for Dropdown and Multiselect fields!";
    exit;
}

$DynamicField->{Config}->{PossibleValues} = \%PossibleValues;

$CommonObject{DynamicFieldObject}->DynamicFieldUpdate(
    %{$DynamicField},
    Reorder => 0,
    UserID  => 1,
);
