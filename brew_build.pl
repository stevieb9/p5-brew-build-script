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

if ($^O eq 'MSWin32'){
    $is_win = 1;
    win_build($num);
}
else {
    unix_build($num);
}

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

sub unix_build {

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

    if ($reload){
        print "\nremoving previous installs...\n" if $debug;

        for (@perls_installed){
            my $ver = $^V;
            $ver =~ s/v//;

            print "skipping version we're using, $_\n" if $debug;
            next if $_ =~ /$ver$/;

            `perlbrew uninstall $_`;
        }

        print "\nremoval of existing perl installs complete...\n" if $debug;
    }
    else {
        print "not rebuilding perlbrew instances...\n";
    }

    if ($num){
        my @new_installs;

        for ($num){
            push @new_installs, $perls_available[rand @perls_available];
        }

        for (@new_installs){
            print "\ninstalling $_...\n" if $debug;
            `perlbrew install --notest -j 4 $_`;
        }
    }
    else {
        print "\nusing existing versions only\n" if $debug;
    }

    my $result;

    if ($debug){
        print "\n...brewing\n" if $debug;
        $result = `perlbrew exec perl build/test.pl`;
        print "...done brew\n" if $debug;
    } 
    else {
        $result = `perlbrew exec build/test.pl 2>/dev/null`;
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
sub win_build {

    my $num = shift;

    if ($ENV{PATH} !~ /berrybrew/){
        warn "\nberrybrew not found on Windows system\n";
        return;
    }

    my $brew_info = `berrybrew available`;

    my @perls_available 
      = $brew_info =~ /(\d\.\d{2}\.\d(?:_\d{2}))(?!=_)/g;

    $num = scalar @perls_available if $num =~ /all/;

    my @perls_installed

    my %perl_vers;

    print "\nremoving previous installs...\n" if $debug;

    for (@perls_installed){
        `berrybrew remove $_` if $reload;
    }

    print "\nremoval of existing perl installs complete...\n" if $debug;

    my @new_installs;

    for (1..$num){
        push @new_installs, $perls_available[rand @perls_available];
    }

    for (@new_installs){
        print "\ninstalling $_...\n" if $debug;
        `berrybrew install $_` if $reload;
    }

    print "\nexecuting commands...\n" if $debug;

    my $result = `berrybrew exec perl build\\test.pl`;

    my @ver_results = split /\n\n\n/, $result;

    my $ver;

    print "\n\n";

    for (@ver_results){
        if (/^Perl-(\d\.\d+\.\d+.*)/){
            $ver = $1;
        }
        my $res;
        if (/Result:\s+(PASS)/){
           $res = $1; 
        }
        else {
            $res = 'FAIL';
        }
        print "$ver :: $res\n";
    }
}
