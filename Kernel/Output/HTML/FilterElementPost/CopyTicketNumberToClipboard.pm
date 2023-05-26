# --
# Copyright (C) 2017 - 2023 Perl-Services.de, https://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::CopyTicketNumberToClipboard;

use strict;
use warnings;

use Kernel::System::ObjectManager;

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Web::Request
    Kernel::Output::HTML::Layout
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $TemplateName = $Param{TemplateFile} || '';

    # get template name
    return 1 if !$Param{Templates}->{$TemplateName};

    my $Template = $ConfigObject->Get('CopyTicketNumberToClipboard::Template');

    ${ $Param{Data} } =~ s{
        <div \s+ class="Headline[^"]*"> \s+
            <div \s+class="Flag[^"]*" .*?
                <h1 [^>]*> \s+ \K (.*) \s+ ((?:<span>)?&mdash;(?:</span>)?)
    }{$1 . $Self->_BuildHTML(Template => $Template, Tn => $1) . $2 }xsme;

    return 1;
}

sub _BuildHTML {
    my ($Self, %Param) = @_;

    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    my $Hook    = $ConfigObject->Get('Ticket::Hook');
    my $Divider = $ConfigObject->Get('Ticket::HookDivider');

    my $TicketNumber = $Param{Tn};
    $TicketNumber =~ s{\A\s*\[}{};
    $TicketNumber =~ s{\]\s*\z}{};
    $TicketNumber =~ s{\A$Hook$Divider}{};

    my $CopyValue = $LayoutObject->Output(
        Template => $Param{Template},
        Data     => {
            TicketNumber => $TicketNumber,
        },
    );

    my $HTMLTemplate = q~
        <i class="fa fa-clipboard pointer" id="CopyTicketNumberIcon"
             onclick="copyToClipboard('[% Data.Value | html %]');"></i>
        <script type="text/javascript">//<![CDATA[
             function copyToClipboard(text) {
                $('#CopyTicketNumberIcon').addClass('pulsing');

                if ( !navigator.clipboard ) {
                    $('#CopyTicketNumberIcon').addClass('pulsing');
                    if (window.clipboardData) { // Internet Explorer
                        window.clipboardData.setData("Text", text);
                    } else {
                        var target = document.createElement("textarea");
                        target.style.position = "absolute";
                        target.style.left = "10px";
                        target.style.top = "0";
                        target.textContent = text;

                        document.body.appendChild(target);

                        var range = document.createRange();
                        range.selectNode(target);
                        window.getSelection().addRange(range);

                        try {
                          var successful = document.execCommand('copy');
                          var msg = successful ? 'successful' : 'unsuccessful';
                          //console.debug('Copying text command was ' + msg);
                        } catch (err) {
                          //console.debug('Oops, unable to copy');
                        }

                        document.body.removeChild(target);
                    }
                }
                else {
                    navigator.clipboard.writeText(text).then( function() {
                        //console.debug('Copying text command was successful');
                    }, function (err) {
                        //console.debug('Oops, unable to copy');
                    });
                }

                window.setTimeout( function() { $('#CopyTicketNumberIcon').removeClass('pulsing'); }, 1000 );
            }
        //]]></script>
    ~;

    my $HTML = $LayoutObject->Output(
        Template => $HTMLTemplate,
        Data     => {
            Value => $CopyValue,
        },
    );

    return $HTML;
}

1;

