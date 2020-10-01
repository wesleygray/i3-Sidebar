#!/usr/bin/perl                                                                                                                

# ASCII codes from:                                                                                                            
# http://www.theasciicode.com.ar/ascii-printable-characters/vertical-bar-vbar-vertical-line-vertical-slash-ascii-code-124.html

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

sub addgraphval {
    my($vals, $newval) = @_;

    unshift @$vals, $newval;
    if (scalar(@$vals) > $barwidth) {
        pop(@$vals);
    }
}

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

sub printblock {
    my($count, $char) = @_;

    for (my $x=1; $x <= $count; $x++) {
        print SBFILE $char;
    }
}

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
$i3_monitor=$ENV{"I3_MONITOR"};
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

