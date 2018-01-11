#!/usr/bin/perl

#
# i3-sidebar.pl - A simple terminal program to generate a sidebar of
#    weather and system information, written in Perl.
#
# Version 0.1.0
#
# Released under the GNU GPL version 3.  A text version of the GPL should have come
# with this program in the file "COPYING".
#
# Copyright 2018 Wes Gray
#

# ASCII codes from:
# http://www.theasciicode.com.ar/ascii-printable-characters/vertical-bar-vbar-vertical-line-vertical-slash-ascii-code-124.html

# this function converts the strings that come from yahoo into
# a 5 character ascii representation of the weather
sub getweathericon {
    my($weather) = @_;
    if ($weather eq "Cloudy") { $weather="#####"; }
    if ($weather eq "Mostly Cloudy") { $weather="*####"; }
    if ($weather eq "Partly Cloudy") { $weather="**###"; }
    if ($weather eq "Fair") { $weather="****#"; }
    if ($weather eq "Sunny") { $weather="*****"; }
    if ($weather eq "Showers") { $weather="/////"; }
    if ($weather eq "Scattered Thunderstorms") { $weather="#z#z#"; }
    if ($weather eq "Scattered Thundersto") { $weather="#z#z#"; }
    if ($weather eq "Scattered Showers") { $weather="#/#/#"; }
    if ($weather eq "Scattered Sho") { $weather="#/#/#"; }
    if ($weather eq "Isolated Thundershowers") { $weather="#z#z/"; }
    if ($weather eq "FairMost") { $weather="****#"; }
    return($weather);
}

sub weather {

    # Open yahoo for reading, to get the URL for your area browse to yahoo and search for it
    open INFILE, "w3m https://www.yahoo.com/news/weather/united-states/santa-cruz/santa-cruz-12797543 |";

    # Open output file for writing
    open OUTFILE, '>', $home . "/.i3-weather";

    # Step through file looking for line to replace
    my($count)=0;
    my($nextday)="";
    my($anchor)=0;
    my($now)="";
    my($curdow)=`date +%A`;
    my($daycount)=0;
    chomp($curdow);
    while (<INFILE>) {
        $count++;
        if ($_ =~ /^United States$/) {
            $anchor=$count;
        }
        if ($anchor != 0 and ($anchor + 2) == $count) {
            chomp($_);
            $_=substr($_, 0, length($_) / 2);
            my($weather_icon)=getweathericon($_);
            printf(OUTFILE "Now:   %-11s", "$weather_icon");
        }
        if ($anchor != 0 and ($anchor + 5) == $count) {
            print OUTFILE "$_\n";
        }

        if ($nextday ne "") {
            $daycount++;
            if ($daycount <= 6) {
                $nextday=~s/Monday/Mon/;
                $nextday=~s/Tuesday/Tue/;
                $nextday=~s/Wednesday/Wed/;
                $nextday=~s/Thursday/Thr/;
                $nextday=~s/Friday/Fri/;
                $nextday=~s/Saturday/Sat/;
                $nextday=~s/Sunday/Sun/;
                my($weather, $rest) = split /Precipitation: [0-9]*%[0-9]*%/, $_;
                $rest=substr($rest, 0, 6);
                my($high, $low) = split /°/, $rest;
                # $weather=~s/Scattered //;

                # figure out the weather icon
                my($weather_icon)=getweathericon($weather);

                # print weather
                printf(OUTFILE "%-7s", "$nextday: ");
                printf(OUTFILE "%-11s", "$weather_icon");
                print OUTFILE "$low°/$high°\n";
                # printf(OUTFILE "%-7s", " ");
                # printf(OUTFILE "%-14s", "$weather");
                # print OUTFILE "\n";
            }
            $nextday="";
        }

        if ($_ =~ 'Monday' or $_ =~ 'Tuesday' or
            $_ =~ 'Wednesday' or $_ =~ 'Thursday' or
            $_ =~ 'Friday' or $_ =~ 'Saturday' or
            $_ =~ 'Sunday') {
            chomp($_);
            $nextday=$_;
            # if ($nextday eq $curdow) {
            #     $nextday="Today";
            # }
        }
    }

    # Close file handles
    close INFILE;
    close OUTFILE;
}

# this function generates one line of a 2 line graph
# the different levels give the threshholds to use for the 3
# levels _-¯
sub graph {
    my($vals, $max, $lev1, $lev2, $lev3, $lev4) = @_;
    my @values = @{ $vals };

    foreach my $val(@values) {
        if ($val > $max) {
            $val=$max;
        }
        $val=$val / $max * 100;
        if ($val > $lev1 & $val <= $lev2) {
            print SBFILE "_";
        } elsif ($val > $lev2 & $val <= $lev3) {
            print SBFILE "─";
        } elsif ($val > $lev3 & $val <= $lev4) {
            print SBFILE "¯";
        } else {
            print SBFILE " ";
        }
    }
    print SBFILE "\n";
}

# this function adds a new value to the left of the array tracking
# the graph values, and removes one from the right
sub addgraphval {
    my($vals, $newval) = @_;

    unshift @$vals, $newval;
    if (scalar(@$vals) > $barwidth) {
        pop(@$vals);
    }
}

# this function reads a value from the given file and adds it to the
# given graph value array
sub readval {
    my($vals, $fname) = @_;
    open(VFILE, $home . "/" . $fname) || die "Can't open file .  $!\n";
    $val = <VFILE>;
    chomp($val);
    addgraphval($vals, $val);
    return($val);
}

sub grepfromarray {
    my($searchval, $arr) = @_;
    @resultarr = grep { $_ =~ $searchval } @$arr;
    $result=@resultarr[0];
    $result =~ s/\D//g;
    return($result);
}

# print the given number blocks
sub printblock {
    my($count, $char) = @_;

    for (my $x=1; $x <= $count; $x++) {
        print SBFILE $char;
    }
}

# prints a section header
sub printheader {
    my($str) = @_;

    $strlen=length($str) + 2; # +2 for spaces
    $leftcount=int($barwidth / 2) - int($strlen / 2) - 1;
    $rightcount=$barwidth - $strlen - $leftcount;
    printblock($leftcount, "▓");
    print SBFILE " $str ";
    printblock($rightcount, "▓");
    print SBFILE "\n";
}

sub printbar {
    printblock($barwidth, "▄");
    print SBFILE "\n";
}

# get some env variables
$home=$ENV{"HOME"};
$sbfile=$home . "/.i3_sidebar";
$barwidth=28;

# define the graph arrays
my @cpus = ();
my @gpus = ();
my @netin = ();
my @netout = ();
my @mems = ();


$count=1;
while (1) {

    # open output file used for buffering
    open SBFILE, '>', $sbfile;

    # clear screen
    print SBFILE "\033[2J";
    print SBFILE "\033[0;0H";

    # weather
    printheader("Weather");
    if ($count == 1) {
        weather();
    }
    open(WFILE, $home . "/.i3-weather") || die "Can't open file .  $!\n";
    print SBFILE (<WFILE>);
    close(WFILE);
    print SBFILE "\n";

    # proclist
    printheader("Process List");
    print SBFILE `ps -Ao comm,pcpu,pmem --sort=-pcpu | head -n 10`;

    # cpu
    my($currentcpu)=readval(\@cpus, ".i3-cpu");
    printbar();
    print SBFILE "CPU ($currentcpu%):\n";
    graph(\@cpus, 100, 31, 50, 70, 100);
    graph(\@cpus, 100, 5, 10, 20, 30);

    # gpu
    if ($i3_monitor eq "home") {
        my @gpu = split /\s+/, `nvidia-smi | grep '%'`;
        my($gpuval)=$gpu[4];
        $gpuval =~ s/\D//g;
        addgraphval(\@gpus, $gpuval);
        printbar();
        print SBFILE "GPU ($gpu[1] $gpu[2] $gpu[4]):\n";
        graph(\@gpus, 200, 51, 68, 84, 100);
        graph(\@gpus, 200, 1, 17, 34, 50);
    }

    # get memory usage
    @meminfo = `cat /proc/meminfo`;
    $memtotal=grepfromarray("MemTotal", \@meminfo);
    $memfree=grepfromarray("MemAvailable", \@meminfo);
    $memusage=$memtotal - $memfree;
    $mempercent=int($memusage / $memtotal * 100);

    # get swap usage
    $swaptotal=grepfromarray("SwapTotal", \@meminfo);
    $swapfree=grepfromarray("SwapFree", \@meminfo);
    $swapusage=$swaptotal - $swapfree;
    $swappercent=int($swapusage / $swaptotal * 100);

    # show memory/swap usage
    addgraphval(\@mems, $mempercent);
    printbar();
    print SBFILE "Memory ($mempercent%, $swappercent%SWAP):\n";
    graph(\@mems, 100, 51, 68, 84, 100);
    graph(\@mems, 100, 1, 17, 34, 50);

    # net-in
    readval(\@netin, ".i3-bandwidth-in");
    printbar();
    print SBFILE "Network IN:\n";
    graph(\@netin, 2000000, 31, 60, 84, 100);
    graph(\@netin, 2000000, 1, 3, 10, 20);

    # net-out
    readval(\@netout, ".i3-bandwidth-out");
    printbar();
    print SBFILE "Network OUT:\n";
    graph(\@netout, 500000, 31, 60, 84, 100);
    graph(\@netout, 500000, 1, 3, 10, 20);

    printbar();

    # Close file write handle
    close SBFILE;

    # then open it for reading and print it
    open(SBFILE, $sbfile) || die "Can't open file .  $!\n";
    print (<SBFILE>);
    close(SBFILE);

    sleep 5;
    $count++;
    if ($count > 360) {
        $count=1;
    }
}
