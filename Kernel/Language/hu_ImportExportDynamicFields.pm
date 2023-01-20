# --
# Kernel/Language/hu_ImportExportDynamicFields.pm - the Hungarian translation for ImportExportDynamicFields
# Copyright (C) 2011 - 2023 Perl-Services, https://www.perl-services.de
# Copyright (C) 2016 Balázs Úr, http://www.otrs-megoldasok.hu
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::hu_ImportExportDynamicFields;

use strict;
use warnings;
use utf8;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    # Kernel/Config/Files/ImportExportDynamicFields.xml
    $Lang->{'Override existing dynamic fields when a field with an existing name is imported.'} =
        'Meglévő dinamikus mezők felülírása, ha egy létező névvel rendelkező mező kerül importálásra.';

    return 1;
}

1;
