# --
# Copyright (C) 2017 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminImportExportDynamicFields;

use strict;
use warnings;

my @ObjectDependencies = qw(
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
    Kernel::System::DynamicField::PerlServicesUtils
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # check needed objects
    for my $NeededData (qw(Subaction UserID)) {
        if ( !$Param{$NeededData} ) {
            $LayoutObject->FatalError( Message => "Got no $NeededData!" );
        }
        $Self->{$NeededData} = $Param{$NeededData};
    }

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ImExObject   = $Kernel::OM->Get('Kernel::System::DynamicField::PerlServicesUtils');

    if ( $Self->{Subaction} eq 'Export' ) {

        my %Opts;

        my $Name = $ParamObject->GetParam( Param => 'Name' );
        if ( $Name ) {
            $Opts{IDs} = [ $Name ];
        }

        my $JSON = $ImExObject->DynamicFieldsExport(
            %Opts,
        );

        return $LayoutObject->Attachment(
            Filename    => 'DynamicFields.json',
            Content     => $JSON,
            ContentType => 'text/json',
        );

    }

    # ---------------------------------------------------------- #
    # show import screen
    # ---------------------------------------------------------- #
    elsif ( $Self->{Subaction} eq 'Import' ) {

        # get params
        $Param{Status} = $ParamObject->GetParam( Param => 'Status' );

        # importing
        if ( $Param{Status} && $Param{Status} eq 'Action' ) {

            # challenge token check for write action
            $LayoutObject->ChallengeTokenCheck();

            my $Uploadfile = '';
            if ( $Uploadfile = $ParamObject->GetParam( Param => 'file_upload' ) ) {
                my %UploadStuff = $ParamObject->GetUploadAll(
                    Param    => 'file_upload',
                    Encoding => 'Raw'
                );

                my $Success = $ImExObject->DynamicFieldsImport(
                    Fields => $UploadStuff{Content},
                    UserID => $Self->{UserID},
                );

                if ( $Success ) {
                    return $LayoutObject->Redirect( OP => 'Action=AdminDynamicField' );
                }
            }
        }

        # show import form
        my $Output = $LayoutObject->Header( Title => 'Import' );
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Output( TemplateFile => 'AdminImportDynamicFields' );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ---------------------------------------------------------- #
    # show error screen
    # ---------------------------------------------------------- #
    return $LayoutObject->ErrorScreen( Message => 'Invalid Subaction process!' );
}

1;
