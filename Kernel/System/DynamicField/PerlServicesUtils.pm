# --
# Kernel/System/DynamicField/PerlServicesUtils.pm - Utility module for DynamicFields provided by Perl-Services.de
# Copyright (C) 2013 - 2022 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::DynamicField::PerlServicesUtils;

use strict;
use warnings;

use JSON;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::DB
    Kernel::System::Cache
    Kernel::System::JSON
    Kernel::System::DynamicField
    Kernel::System::Valid
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');

    # set lower if database is case sensitive
    $Self->{Lower} = '';
    if ( !$DBObject->GetDatabaseFunction('CaseInsensitive') ) {
        $Self->{Lower} = 'LOWER';
    }


    return $Self;
}

sub FieldLookup {
    my ($Self, %Param) = @_;

    my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

    if ( $Param{Name} ) {
        my $CheckSQL  = "SELECT id FROM dynamic_field WHERE $Self->{Lower}(name) = $Self->{Lower}(?)";

        return if !$DBObject->Prepare(
            SQL   => $CheckSQL,
            Bind  => [ \$Param{Name} ],
            Limit => 1,
        );

        my $ID;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $ID = $Row[0];
        }

        return if !$ID;
        return $ID;
    }

    return;
}

sub DynamicFieldsExport {
    my ($Self, %Param) = @_;

    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');

    my $SQL = 'SELECT id, name, label, field_order, field_type, object_type, config, valid_id '
        . ' FROM dynamic_field';

    my @Bind;
    if ( $Param{IDs} && ref $Param{IDs} eq 'ARRAY' ) {
        my $Placeholder = join ', ', ('?') x @{$Param{IDs}};

        $SQL .= ' WHERE id IN( ' . $Placeholder . ')';
        @Bind = map{ \$_ }@{$Param{IDs}};
    }

    return '[]' if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my @Fields;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my %Field = (
            Name       => $Row[1],
            Label      => $Row[2],
            FieldOrder => $Row[3],
            FieldType  => $Row[4],
            ObjectType => $Row[5],
            Config     => $Row[6],
        );

        $Field{Valid} = $ValidObject->ValidLookup( ValidID => $Row[7] );

        push @Fields, \%Field;
    }

    my $JSON = $JSONObject->Encode(
        Data => \@Fields,
    ); 

    return $JSON;
}

sub DynamicFieldsImport {
    my ($Self, %Param) = @_;

    my $DBObject     = $Kernel::OM->Get('Kernel::System::DB');
    my $ValidObject  = $Kernel::OM->Get('Kernel::System::Valid');
    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');
    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $CacheObject  = $Kernel::OM->Get('Kernel::System::Cache');

    for my $Needed ( qw(Fields UserID) ) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $DoOverride = $ConfigObject->Get( 'DynamicFieldsImport::DoOverride' );

    my $Fields;
    eval {
        #$Fields = $JSONObject->Decode(
        #    Data => $Param{Fields},
        #);
        $Fields = JSON->new->allow_nonref(1)->utf8(1)->decode( $Param{Fields} );
    };

    return if !$Fields;

    my $InsertSQL = 'INSERT INTO dynamic_field (name, label, field_order, field_type, object_type,' .
        'config, valid_id, create_time, create_by, change_time, change_by)' .
        ' VALUES (?, ?, ?, ?, ?, ?, ?, current_timestamp, ?, current_timestamp, ?)',

    my $CheckSQL  = "SELECT id FROM dynamic_field WHERE $Self->{Lower}(name) = $Self->{Lower}(?)";

    my $UpdateSQL = 'UPDATE dynamic_field SET name = ?, label = ?, field_order = ?, field_type = ?, ' .
        'object_type = ?, config = ?, valid_id = ?, change_by = ?, change_time = current_timestamp ' .
        ' WHERE id = ?';

    FIELD:
    for my $Field ( @{$Fields} ) {
        next FIELD if !$DBObject->Prepare(
            SQL   => $CheckSQL,
            Bind  => [ \($Field->{Name}) ],
            Limit => 1,
        );

        my $ID;
        while ( my @Row = $DBObject->FetchrowArray() ) {
            $ID = $Row[0];
        }

        next FIELD if $ID && !$DoOverride;

        $Field->{ValidID} = $ValidObject->ValidLookup( Valid => $Field->{Valid} ) || 1;

        if ( $ID ) {
            next FIELD if !$DBObject->Do(
                SQL  => $UpdateSQL,
                Bind => [
                    \$Field->{Name},
                    \$Field->{Label},
                    \$Field->{FieldOrder},
                    \$Field->{FieldType},
                    \$Field->{ObjectType},
                    \$Field->{Config},
                    \$Field->{ValidID},
                    \$Param{UserID},
                    \$ID,
                ],
            );
        } 
        else {
            next FIELD if !$DBObject->Do(
                SQL  => $InsertSQL,
                Bind => [
                    \$Field->{Name},
                    \$Field->{Label},
                    \$Field->{FieldOrder},
                    \$Field->{FieldType},
                    \$Field->{ObjectType},
                    \$Field->{Config},
                    \$Field->{ValidID},
                    \$Param{UserID},
                    \$Param{UserID},
                ],
            );
        }
    }

    $CacheObject->CleanUp(
        Type => 'DynamicField',
    );

    return 1;
}

1;
