use strict;
use warnings;

use LWP::Simple;
use LWP::UserAgent;
use File::Copy;
require HTML::TokeParser;

my @months = qw( janurary february march april may june july august september october november december );
my @days = qw(Sun Mon Tue Wed Thu Fri Sat Sun);
(my $sec, my $min, my $hour, my $mday, my $mon, my $year, my $wday, my $yday, my $isdst) = localtime();
my $date_string = "$months[$mon]-$mday";

my $national_days_list_filename = 'National_Days_List.txt';
my $windows_save_directory = '/mnt/c/Users/nmauro/Desktop/';

sub main {
	my $agent = LWP::UserAgent->new;
    $agent->agent("Mozilla/4.76");
    my $response = $agent->get('https://www.nationaldaycalendar.com/what-day-is-it/');
    $response->is_success or die $response->status_line;

    my $html = HTML::TokeParser->new(\$response->decoded_content) || die "Can't open: $!";
    my %national_day_list;
    while (my $token = $html->get_token) {
        my $val = 4; # value used for parsing the html token fields
        if ($token->[$val]) {
            if ($token->[$val] =~ m|<a href="https://nationaldaycalendar.com/(.+$date_string)|) {
                my $text = $1;

                # grab the text and remove the date
                $text =~ s/$date_string//g;

                # remove the dashes
                $text =~ s/-/ /g;

                # upper case the first letter
                my $final_text = ucfirst("$text");

                if (! exists $national_day_list{$final_text}) {
                    $national_day_list{$final_text} = 1;
                }
            }
        };
    }

    print_national_days(\%national_day_list);
    copy_file();
}

sub print_national_days {
    my $national_day_list = shift;

    open(my $NATIONAL_DAYS, '>', $national_days_list_filename) or die $!;

    my $formatted_year = 1900 + $year;
    my $formatted_month = ucfirst($months[$mon]);
    my $nice_date_string = "$formatted_month $mday, $formatted_year";
    print $NATIONAL_DAYS "Todays National Day Report for $nice_date_string \n";

    foreach my $day (keys %{$national_day_list}) {
        print $NATIONAL_DAYS "- $day \n";
    }

    close($NATIONAL_DAYS);
}

sub copy_file {
    if (! copy("./$national_days_list_filename", $windows_save_directory)) {
        print "Failed to copy file... \n";
    }
}

main();
