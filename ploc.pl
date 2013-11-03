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

my $log = defined $OUTFILE? $OUTFILE : "lines.txt";
my @matches;
my $pattern;
my $lang;

if (!defined $LANG && !defined $PATTERN)
{
    $lang = "text";
    $pattern = "[.].*\$";
}
elsif (!defined $LANG)
{
    $pattern = $PATTERN;
    $lang = "/$pattern/";
} 
else
{
    given($LANG)
    {
        when(m/as3/i)
        {
            $lang = "ActionScript3";
            $pattern = '[.](as)$';
        }
        when(m/scala/i) 
        {
            $lang = "scala";
            $pattern = '[.](java|scala)$';
        }
        when(m/java/i)
        {
            $lang = "java";
            $pattern = '[.]java$';
        } 
        when(m/c#|cs/i)
        {
            $lang = "C#";
            $pattern = '[.]cs$';
        }
        when(m/c\+\+/i)
        {
            $lang = "C++";
            $pattern = '[.](cpp|h|hpp|cxx|hxx)$';
        }
        when(m/c/i)
        {
            $lang = "C";
            $pattern = '[.](c|h|l|y)$';
        }
        when(m/python/i)
        {
            $lang = "Python";
            $pattern = '[.](py|pyw)$';
        }
        when(m/perl/i)
        {
            $lang = "Perl";
            $pattern = '[.](pl|pm|plx)$';
        }
        when(m/ocaml/i)
        {
            $lang = "OCaml";
            $pattern = '[.](ml|mli|sml|thy|mly|mll)$';
        }
        when(m/asm|assembly/i) 
        {
            $lang = "Assembly";
            $pattern = '[.](s|asm|sml|thy)$';
        }
        when(m/shell|sh|bash|ksh|csh/i)
        {
            $lang = "sh";
            $pattern = '[.]([kbc]?sh)$';
        }
        default
        {
            $lang = "text";
        }
    }
}


say "Matching $lang files";
chdir $DIRNAME if defined $DIRNAME;

sub count_lines {
    my $regex = $_[0];
    my $result = "";
    my @all = ();
    foreach my $file (grep /$regex/,`/bin/find .`)
    {
        chomp $file;
        #$file =~ s/ /\\ /g;
        push @all, "\"$file\"";
    }
    my $joined = join(" ", @all);
    my @result = `cl.exe $joined`;
    return @result;
}


#my $text = `cl.exe -l < @matches`;
my @lines = count_lines($pattern);
my $cnt = scalar @lines;
my $total = 0;
my @formatted_lines = ();
foreach my $line (@lines)
{
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

if ($QUIET)
{
    print "$total\n";
}
else 
{
    foreach my $line (sort @formatted_lines)
    {
        print $line;
    }
    printf "\n%10s [%5s] TOTAL\n", $total, $lang;
}

system("echo $total, `date +%s` >> $log");

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
