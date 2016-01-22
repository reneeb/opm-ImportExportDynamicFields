# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::DynamicFields::Import;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Main
    Kernel::System::DynamicField::PerlServicesUtils
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Import DynamicField configuration');

    $Self->AddOption(
        Name        => 'file',
        Description => "Read the configuration from that file",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );


    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Import dynamic field configuration...</yellow>\n");

    my $File       = $Self->GetOption('file');
    my $ContentRef = $MainObject->FileRead(
        Location => $File,
    );

    $UtilObject->DynamicFieldsImport(
        Fields => ${$ContentRef},
        UserID => 1,
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
