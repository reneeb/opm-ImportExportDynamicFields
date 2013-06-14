#!/usr/bin/perl

# --
# bin/ps.ImportExportDynamicFields.pl - import/export dynamic fields
# Copyright (C) 2013 Perl-Services.de, http://perl-services.de
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
    'm=s' => \$opts{m},
    'f=s' => \$opts{f},
);

use Kernel::Config;
use Kernel::System::Encode;
use Kernel::System::Log;
use Kernel::System::Time;
use Kernel::System::Main;
use Kernel::System::DB;
use Kernel::System::DynamicField::PerlServicesUtils;

# create common objects
my %CommonObject = ();
$CommonObject{ConfigObject} = Kernel::Config->new(%CommonObject);
$CommonObject{EncodeObject} = Kernel::System::Encode->new(%CommonObject);
$CommonObject{LogObject}    = Kernel::System::Log->new(
    LogPrefix => 'OTRS-ps.ImportExportDynamicFields.pl',
    %CommonObject,
);
$CommonObject{TimeObject} = Kernel::System::Time->new(%CommonObject);
$CommonObject{MainObject} = Kernel::System::Main->new(%CommonObject);
$CommonObject{DBObject}   = Kernel::System::DB->new(%CommonObject);
$CommonObject{UtilObject} = Kernel::System::DynamicField::PerlServicesUtils->new(%CommonObject);

$opts{m} ||= 'export';
$opts{m} = lc $opts{m};

if (
    ($opts{m} ne 'export' && $opts{m} ne 'import' ) || 
    ($opts{m} eq 'import' && 
        ( !$opts{f} || !-f $opts{f} )
    )
) {
    print STDERR qq~$0 [-m <mode>] [-f <file> ] [fieldname1 fieldname2]

m            mode   export or import
f            in export mode path to the file the export should be written to (optional)
             in import mode path to the file that should be imported (mandatory)
fieldname#   in export mode the names of the to be exported fields

Example:

  $0 -m export Test1 Test2 

  exports only the fields Test1 and Test2
~;
}

if ( $opts{m} eq 'export' ) {
    my %Params;

    if ( @ARGV ) {
        my @IDs;
        for my $Name ( @ARGV ) {
            push @IDs, $CommonObject{UtilObject}->FieldLookup( Name => $Name );
        }

        $Params{IDs} = \@IDs if @IDs;
    }

    my $JSON = $CommonObject{UtilObject}->DynamicFieldsExport(
        %Params,
    );

    if ( !$opts{f} ) {
        print $JSON;
    }
    else {
        $CommonObject{MainObject}->FileWrite(
            Location => $opts{f},
            Content  => \$JSON,
        );
    }
}
else {
    my $ContentRef = $CommonObject{MainObject}->FileRead(
        Location => $opts{f},
    );

    $CommonObject{UtilObject}->DynamicFieldsImport(
        Fields => ${$ContentRef},
        UserID => 1,
    );
}
