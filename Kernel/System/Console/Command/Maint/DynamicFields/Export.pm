# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::DynamicFields::Export;

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

    $Self->Description('Export DynamicField configuration');
    $Self->AddOption(
        Name        => 'field',
        Description => "Name of the dynamic field that should be exported.",
        Required    => 0,
        HasValue    => 1,
        Multiple    => 1,
        ValueRegex  => qr/.*/smx,
    );

    $Self->AddOption(
        Name        => 'file',
        Description => "Write the configuration to that file",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/smx,
    );


    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    $Self->Print("<yellow>Export dynamic field configuration...</yellow>\n");

    my %Params;

    my @Names = @{ $Self->GetOptions('field') || [] };
    if ( @Names ) {
        my @IDs;
        for my $Name ( @Names ) {
            push @IDs, $UtilObject->FieldLookup( Name => $Name );
        }

        $Params{IDs} = \@IDs if @IDs;
    }

    my $JSON = $UtilObject->DynamicFieldsExport(
        %Params,
    );

    my $File = $Self->GetOption('file');
    if ( !$File ) {
        print $JSON;
    }
    else {
        $MainObject->FileWrite(
            Location => $File,
            Content  => \$JSON,
        );
    }

    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
