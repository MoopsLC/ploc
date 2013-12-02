#!/usr/bin/perl -w
use strict;

use Getopt::Long;
use Pod::Usage;
use File::Basename;
use feature "switch";
Getopt::Long::Configure ('bundling');

my $HELP = undef;
my $PATTERN = undef;
my $DIRNAME = undef;
my $QUIET = undef;
my $LANG = undef;
my $OUTFILE = undef;

my $find = '/bin/find';# cygwin hack

GetOptions( 'p|pattern=s'   => \$PATTERN,
            'l|lang=s'      => \$LANG,
            'd|directory=s' => \$DIRNAME,
            'q|quiet'       => \$QUIET,
            'o|out=s'       => \$OUTFILE,
            'h|help'        => \$HELP);

pod2usage(1) if $HELP;

sub say {
    print "|[count]|: $_[0]\n" if !$QUIET;
}

sub chooseLanguage {
    my ($lang, $pattern) = @_;
    if (!defined $lang && !defined $pattern) {
        return ("text", "[.].*\$");
    } elsif (!defined $lang) {
        return ("(pattern)", "/$pattern/");
    } else {
        given($lang) {
            when(m/as3/i) {
                return ("ActionScript3", '[.](as)$');
            }
            when(m/scala/i) {
                return ("scala", '[.](java|scala)$');
            }
            when(m/java/i) {
                return ("java", '[.]java$');
            }
            when(m/c#|cs/i) {
                return ("C#", '[.]cs$');
            }
            when(m/c\+\+/i) {
                return ("C++", '[.](cpp|h|hpp|cxx|hxx)$');
            }
            when(m/c/i) {
                return ("C", '[.](c|h|l|y)$');
            }
            when(m/python/i) {
                return ("Python", '[.](py|pyw)$');
            }
            when(m/perl/i) {
                return ("Perl", '[.](pl|pm|plx)$');
            }
            when(m/ocaml/i) {
                return ("OCaml", '[.](ml|mli|sml|thy|mly|mll)$');
            }
            when(m/asm|assembly/i) {
                return ("Assembly", '[.](s|asm|sml|thy)$');
            }
            when(m/shell|sh|bash|ksh|csh/i) {
                return ("sh", '[.]([kbc]?sh)$');
            }
            when(m/haskell|hs|lhs/i) {
                return ("Haskell", '[.]([l]?hs)$');
            }
            when(m/idris|idr/i) {
                return ("Idris", '[.]([l]?idr)');
            }
            default {
                return ("text", $pattern);
            }
        }
    }
}



sub count_file {
    my $filename = $_[0];
    my $lines = 0;
    my $buffer;
    #thank you to nuance from perlmonks
    open(my $handle, $filename) or die "Failed to open $filename";
    while (sysread $handle, $buffer, 4096) {
        $lines += ($buffer =~ tr/\n//);
    }
    close $handle;
    return "$lines,$filename";
}

sub count_lines {
    my $regex = $_[0];
    my $result = "";
    my @all = ();
    foreach my $file (grep /$regex/,`$find .`) {
        chomp $file;
        push @all, "$file";
    }
    my @result = map(count_file($_), @all);
    return @result;
}

sub outputLines {
    my $log = shift @_;
    my $lang = shift @_;
    my @lines = @_;
    my $total = 0;
    my @formatted_lines = ();
    foreach my $line (@lines) {
        chomp $line;
        my @entry = split /,/, $line, 2;
        my $num = $entry[0];
        my $name = $entry[1];
        my $base = basename $name;
        my $type = $base;
        $type =~ s/[^.]*[.](.*)/$1/;
        my $formatted = sprintf "%6s%04d [%5s] $base\n", "", $num, $type;
        push(@formatted_lines, $formatted);
        $total += $num;
    }

    if (!$QUIET) {
        foreach my $line (sort @formatted_lines) {
            print $line;
        }
        printf "\n%10s [%5s] TOTAL\n", $total, $lang;
    }

    system("echo $total, `date +%s` >> $log");
}

sub main {

    my $log = defined $OUTFILE? $OUTFILE : "lines.txt";
    my @matches;
    my ($lang, $pattern) = chooseLanguage($LANG, $PATTERN);
    if (! (defined $lang) || !(defined $pattern)) {
        say "unknown language: $LANG";
        exit(1);
    }
    say "Matching $lang files";
    chdir $DIRNAME if defined $DIRNAME;

    my @lines = count_lines($pattern);
    outputLines($log, $lang, @lines);
}

main()



__END__
=head1 NAME
report - This is what it does

=head1 SYNOPSIS

count [OPTIONS]

Counts the number of lines present in files. By default, searches the current
directory for all files and counts the number of '$/' separated lines. The
search may be refined by a choice of directory, language, or user specified
pattern.

=head1 OPTIONS

=over 16

=item B<-help>

Print a brief help message and exits.

=item B<-l>

Language to match. Choices are java, c#, c++, c, perl, python, ocaml, asm, sh.

=item B<-q>

Quiet mode, only output total.

=item B<-d DIR>

Search only in directory DIR. Default: current directory.

=item B<-p PATTERN>

Use PATTERN to search for files to count.

=back

=head1 DESCRIPTION

Breport will read the given input file(s) and do something
useful with the contents thereof.

=cut
