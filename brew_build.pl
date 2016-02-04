#!/usr/bin/perl
use warnings;
use strict;

use Cwd;

# set $debug to true to print out running info

my $debug = 1;

print "\nUsage: build.pl run_count [reload]\n" if ! defined $ARGV[0];

my $num = $ARGV[0];
my $reload = $ARGV[1];

my $is_win = 0;

run($num);

sub perls_available {
    my $brew_info = shift;

    my @perls_available 
      = $brew_info =~ /(perl-\d\.\d+\.\d+)/g;

    return @perls_available;
}
sub perls_installed {
    my $brew_info = shift;

    return $is_win
        ? $brew_info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)\s+\[installed\]/ig
        : $brew_info =~ /(perl-\d\.\d+\.\d+)/g;
}
sub instance_remove {
    print "\nremoving previous installs...\n" if $debug;

    my $remove_cmd = $is_win
        ? 'berrybrew remove'
        : 'perlbrew uninstall';

    for (@perls_installed){
        my $ver = $^V;
        $ver =~ s/v//;

        print "skipping version we're using, $_\n" if $debug;
        next if $_ =~ /$ver$/;

        `$remove_cmd $_`;
    }

    print "\nremoval of existing perl installs complete...\n" if $debug;
}
sub instance_install {
    
    my $count = shift;

    my $install_cmd = $is_win
        : 'berrybrew install'
        ? 'perlbrew install --notest -j 4';

    my @new_installs;

    for ($num){
        push @new_installs, $perls_available[rand @perls_available];
    }

    for (@new_installs){
        print "\ninstalling $_...\n" if $debug;
        `$install_cmd $_`;
    }
    else {
        print "\nusing existing versions only\n" if $debug;
    }
}
sub results {

    my $exec_cmd = $is_win
        ? 'berrybrew exec perl build\\test.pl'
        : 'perlbrew exec build/test.pl';

    my $debug_exec_cmd = $is_win
        ? 'berrybrew exec perl build\\test.pl'
        : 'perlbrew exec build/test.pl 2>/dev/null';

    my $result;

    print "\n...executing\n" if $debug;

    if ($is_win){
        $result = `$exec_cmd` if $is_win;
    }
    else {
        if ($debug){
            $result = `$debug_exec_cmd`;
        }
        else {
            $result = `$exec_cmd`;
        }
    } 

    my @ver_results = split /\n\n\n/, $result;

    my $i = 0;
    my $ver;

    print "\n\n";

    for (@ver_results){
        if (/^(perl-\d\.\d+\.\d+)/){
            $ver = $1;
        }
        my $res;
        if (/Result:\s+(PASS)/){
            print $_;
            $res = $1; 
        }
        else {
            $res = 'FAIL';
        }
        print "$ver :: $res\n";
    }
}

sub run {

    my $num = shift;

    my $brew_info = `perlbrew available`;
    
    my @perls_available = perls_available($brew_info);

    $num = scalar @perls_available if $num =~ /all/;

    my @perls_installed = perls_installed($brew_info);

    if ($debug){
        print "$_ installed\n" for @perls_installed;
        print "\n";
    }

    my %perl_vers;

    instance_remove() if $reload;
    instance_install($num);

    results();
}
