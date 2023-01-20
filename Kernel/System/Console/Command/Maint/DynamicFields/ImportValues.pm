# --
# Copyright (C) 2017 - 2023 Perl-Services.de, https://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::DynamicFields::ImportValues;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Main
    Kernel::System::CSV
    Kernel::System::DynamicField
    Kernel::System::DynamicField::PerlServicesUtils
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Import values for dropdown DynamicField ');

    $Self->AddOption(
        Name        => 'file',
        Description => "CSV file with values",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'name',
        Description => "name of dynamic field",
        Required    => 1,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Import values for dropdown dynamic field...</yellow>\n");

    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
    my $CSVObject          = $Kernel::OM->Get('Kernel::System::CSV');
    my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField');

    my $File       = $Self->GetOption('file');
    my $ContentRef = $MainObject->FileRead(
        Location => $File,
    );

    my $Values = $CSVObject->CSV2Array(
        String => ${$ContentRef},
    );

    my %PossibleValues;
    for my $Row ( @{ $Values || [] } ) {
        my ($Key, $Value) = @{ $Row || [] };
        $Value //= $Key;

        $PossibleValues{$Key} = $Value;
    }

    my $DynamicField = $DynamicFieldObject->DynamicFieldGet( Name => $Self->GetOption('name') );

    if ( $DynamicField->{FieldType} ne 'Dropdown' and $DynamicField->{FieldType} ne 'Multiselect' ) {
        $Self->PrintError("Importing values is only available for Dropdown and Multiselect fields!");
        return $Self->ExitCodeError();
    }

    $DynamicField->{Config}->{PossibleValues} = \%PossibleValues;

    $DynamicFieldObject->DynamicFieldUpdate(
        %{$DynamicField},
        Reorder => 0,
        UserID  => 1,
    );

    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
