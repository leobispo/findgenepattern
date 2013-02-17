#!/usr/bin/perl

use strict;
use warnings;

my $cmd_line = "";
foreach my $p (@ARGV) {
  $cmd_line = $cmd_line . "$p ";
}



my %COMPLEMENT = ( "A" => "T",
                   "C" => "G",
                   "G" => "C",
                   "T" => "A",
                   "N" => "N",
                   "[" => "[",
                   "]" => "]",
                   "(" => "(",
                   ")" => ")",
                   "-" => "-"
                 );

use State;
use Pattern;
use Summary;

use File::stat;
use Getopt::Long;

my $input_file  = '';
my $output_file = '';
my $search_type = 0;
my $mismatch    = 0;
my $num_process = 1;
my @pattern;
my @pattern_min;
my @label;

GetOptions("input-file=s"  => \$input_file,
           "output-file=s" => \$output_file,
           "search-type=s" => \$search_type,
           "pattern=s"     => \@pattern,
           "mismatch=i"    => \$mismatch,
           "pattern-min=i" => \@pattern_min,
           "label=s"       => \@label,
           "num-process=i" => \$num_process);

if ($input_file eq '' || $output_file eq '' || scalar(@pattern) == 0 || $search_type < 0 
  || $search_type > 1 || $num_process < 1) {
  print_usage($0);
}

if (@pattern != @pattern_min or @pattern != @label) {
  print_usage($0);
}

my $file_size  = get_file_size($input_file);
my $chunk_size = int($file_size / $num_process);

my $start = 0;
my $end   = $chunk_size;

my @all_patterns;

for (my $i = 0; $i < @pattern; ++$i) {
  my @el = split //, $pattern[$i];
  my $str = '';

  for (my $j = 0; $j < @el; ++$j) {
    if ($el[$j] eq 'N') {
      $str .= '[ACGT]';
    }
    else {
      $str .= $el[$j];
    }
  }

  my $new_pattern = new Pattern();

  $new_pattern->set_label($label[$i]);
  $new_pattern->set_min_match($pattern_min[$i]);
  $new_pattern->set_pattern(State::generate_graph($str));

  push(@all_patterns, $new_pattern);
}

for my $p (1 .. $num_process) {
  my $pid = fork();
  if ($pid == -1) {
    die;
  }
  elsif ($pid == 0) {
    main($start, $end, $p);
    exit 0;
  }
  else {
    $start = $end + 1;
    $end   = $start + $chunk_size;

    if ($end > $file_size) {
      $end = $file_size;
    }
  }
}

while (wait() != -1) {}

exit 0;

################################################################################

sub print_usage
{
  my $prog_name = $_[0];
  printf(STDERR "Usage %s [ARGS]\n", $prog_name);
  printf(STDERR "\t--input-file=<file_name>\n");
  printf(STDERR "\t--output-file=<file_name>\n");
  printf(STDERR "\t--search-type=[0|1]\n");
  printf(STDERR "\t--pattern=<search_pattern>\n");
  printf(STDERR "\t--mismatch=[0..n]\n");
  printf(STDERR "\t--num-process=[1..n]\n");
  printf(STDERR "\t--pattern-min=[0..n]\n");
  printf(STDERR "\t--label=<label>\n");
  exit 1;
}

################################################################################

sub get_file_size
{
  my $file = $_[0];
  my $filesize = stat($file)->size;

  return $filesize;
}

################################################################################

sub read_header
{
  my $fin = $_[0];
  my $str = '';

  my $char;
  while ((read $fin, $char, 1) != 0) {
    last if $char eq "\n";
    $str .= $char;
  }

  return $str;
}

################################################################################

sub read_sequence
{
  my $fin = $_[0];
  my @lst;

  my $char;
  while ((read $fin, $char, 1) != 0) {
    next if $char eq "\n";
    last if $char eq ">";
    push(@lst, $char)
  }

  if ($char eq ">") {
    seek($fin, tell($fin) - 1, 0);
  }

  return \@lst;
}

################################################################################

sub process_state
{
  my $sequence = $_[0];
  my $state    = $_[1];
  my $label    = $_[2];
 
  my @start_list;
  my @end_list;
  my @mismatch_list;
  my @summary;

  for (my $i = 0; $i < @$sequence; ++$i) {
    my $j = $i;
    my $num_mismatch = $mismatch;
    my $curr_state = $state;
    my @mismatch_tmp_list;
    my $match = '';
    while ($j < @$sequence) {
      $match .= @$sequence[$j];
      my ($ret, $new_state, $tmp_mismatch) = State::check_state(uc(@$sequence[$j]), $curr_state, $num_mismatch);

      last if $ret == 0;

      push (@mismatch_tmp_list, $j) if ($num_mismatch != $tmp_mismatch);

      $num_mismatch = $tmp_mismatch;

      my $size += keys %${$new_state->get_next_states()};
      if ($size == 0) {
        push (@start_list, $i);
        push (@end_list,   $j);

        my $tmp = new Summary();
        $tmp->set_label($label);
        $tmp->set_start($i + 1);
        $tmp->set_end($j + 1);
        $tmp->set_mismatch_num($mismatch - $num_mismatch);
        $tmp->set_match($match);
        push (@summary, $tmp);

        @mismatch_list = (@mismatch_list, @mismatch_tmp_list);
        last;
      }

      $curr_state = $new_state;

      $j++;
    }
  }

  @mismatch_list = sort {$a <=> $b} @mismatch_list;
  return (\@start_list, \@end_list, \@mismatch_list, \@summary);
}

################################################################################

sub process_compl_state
{
  my $sequence = $_[0];
  my $state    = $_[1];
  my $label    = $_[2];
 
  my @start_list;
  my @end_list;
  my @mismatch_list;
  my @summary;

  for (my $i = @$sequence - 1; $i >= 0; --$i) {
    my $j = $i;
    my $num_mismatch = $mismatch;
    my $curr_state = $state;
    my @mismatch_tmp_list;
    my $match = '';
    while ($j >= 0) {
      last if !defined $COMPLEMENT{@$sequence[$j]};
      $match .= $COMPLEMENT{@$sequence[$j]};
      my ($ret, $new_state, $tmp_mismatch) = State::check_state($COMPLEMENT{uc(@$sequence[$j])}, $curr_state, $num_mismatch);

      last if $ret == 0;

      push (@mismatch_tmp_list, $j) if ($num_mismatch != $tmp_mismatch);

      $num_mismatch = $tmp_mismatch;

      my $size += keys %${$new_state->get_next_states()};
      if ($size == 0) {
        push (@start_list, $j);
        push (@end_list,   $i);

        my $tmp = new Summary();
        $tmp->set_label($label);
        $tmp->set_start($j + 1);
        $tmp->set_end($i + 1);
        $tmp->set_mismatch_num($mismatch - $num_mismatch);
        $tmp->set_match($match);
        push (@summary, $tmp);

        @mismatch_list = (@mismatch_list, @mismatch_tmp_list);
        last;
      }

      $curr_state = $new_state;

      $j--;
    }
  }

  @mismatch_list = sort {$a <=> $b} @mismatch_list;
  @start_list    = sort {$a <=> $b} @start_list;
  @end_list     = sort {$a <=> $b} @end_list;
  return (\@start_list, \@end_list, \@mismatch_list, \@summary);
}

sub process_sequence
{
  my $sequence = $_[0];

  foreach my $p (@all_patterns) {
    my ($start_list, $end_list, $mismatch_list, $summary_list) = process_state($sequence, $p->get_pattern(),
      $p->get_label());

    my ($start_comp_list, $end_comp_list, $mismatch_comp_list, $summary_comp_list) = process_compl_state($sequence, 
      $p->get_pattern(), $p->get_label());

    my $num_of_hits = @$start_list + @$start_comp_list;
    return '' if $num_of_hits < $p->get_min_match();

    $p->set_summary($summary_list);
    $p->set_summary_comp($summary_comp_list);
    $p->set_start($start_list);
    $p->set_start_comp($start_comp_list);
    $p->set_end($end_list);
    $p->set_end_comp($end_comp_list);
    $p->set_mismatch($mismatch_list);
    $p->set_mismatch_comp($mismatch_comp_list);
  }

  my $result = '';
  for (my $i = 0; $i < @$sequence; ++$i) {
    my $css_ref = 0;
    foreach my $p (@all_patterns) {
      my $start = $p->get_start();
      if (defined $start && @$start > 0 && @$start[0] == $i) {
        $result .= "<span class=\"pattern$css_ref\">";
        shift(@$start);
      }

      $css_ref++; 

      my $start_compl = $p->get_start_comp();
      if (defined $start_compl && @$start_compl > 0 && @$start_compl[0] == $i) {
        $result .= "<span class=\"pattern$css_ref\">";
        shift(@$start_compl);
      }

      $css_ref++; 
    }

    foreach my $p (@all_patterns) {
      my $mism = $p->get_mismatch();
      if (defined $mism && @$mism > 0 && @$mism[0] == $i) {
        $result .= "<u>";
      }

      $mism = $p->get_mismatch_comp();
      if (defined $mism && @$mism > 0 && @$mism[0] == $i) {
        $result .= "<u>";
      }
    }

    $result .= @$sequence[$i];

    foreach my $p (@all_patterns) {
      my $mism = $p->get_mismatch();
      if (defined $mism && @$mism > 0 && @$mism[0] == $i) {
        $result .= "</u>";
        shift(@$mism);
      }

      $mism = $p->get_mismatch_comp();
      if (defined $mism && @$mism > 0 && @$mism[0] == $i) {
        $result .= "</u>";
        shift(@$mism);
      }
    }

    foreach my $p (@all_patterns) {
      my $end = $p->get_end();
      if (defined $end && @$end > 0 && @$end[0] == $i) {
        $result .= "</span>";
        shift(@$end);
      }

      $end = $p->get_end_comp();
      if (defined $end && @$end > 0 && @$end[0] == $i) {
        $result .= "</span>";
        shift(@$end);
      }
    }
  }
  
  return $result;
}

################################################################################

sub main
{
  my ($char, $gene);
  my $start = $_[0];
  my $end   = $_[1];
  my $w_num = $_[2];

  print "Worker Started: " . $w_num . "\n";

  $output_file =~ s/$/\_$w_num\.html/g;
  my $summary_file = "summary_" . $output_file;

  open my $fin,  "<", $input_file or die "Cannot open the file $input_file: $!";
  open my $fout, ">", $output_file or die "Cannot open the file $output_file: $!";
  open my $fsut, ">", $summary_file or die "Cannot open the file $summary_file: $!";
  open my $flist, ">", "list.txt" or die "Cannot open the file list.txt: $!";

  seek($fin, $start, 0);
  while ((read $fin, $char, 1) != 0) {
    last if $char eq ">";
  }

  seek($fin, tell($fin) - 1, 0);

  print $fout "<html>\n";
  print $fsut "<html>\n";

  print $fout "  <style type=\"text/css\">\n";
  print $fout "    .pattern0 { color: darkblue; font-weight:bold; }\n";
  print $fout "    .pattern1 { color: lightblue; font-weight:bold; }\n";
  print $fout "    .pattern2 { color: darkgreen; font-weight:bold; }\n";
  print $fout "    .pattern3 { color: lightgreen; font-weight:bold; }\n";
  print $fout "    .pattern4 { color: darkred; font-weight:bold; }\n";
  print $fout "    .pattern5 { color: lightred; font-weight:bold; }\n";
  print $fout "    .pattern6 { color: darkbrown; font-weight:bold; }\n";
  print $fout "    .pattern7 { color: lightbrown; font-weight:bold; }\n";
  print $fout "    .gene {width:800px; word-wrap: break-word;}\n";
  print $fout "  </style>\n";

  print $fout "  <body>\n";
  #Print command-line --------------------------------- 

  print $fsut "<p>\n <font size=2>\n";
  print $fsut("search-parameters:\n\n");
  print $fsut("$cmd_line\n");
  print $fsut "</font></p>\n";

  #----------------------------------------------------

  print $fsut "  <br>";
  print $fsut "  <body>\n    <table border=\"1\">\n";
  print $fsut "      <tr>\n";
  print $fsut "        <td>\n";
  print $fsut "         <h5><center> Sequence Name</center></h5>\n";
  print $fsut "        </td>\n";
  print $fsut "        <td>\n";
  print $fsut "         <h5><center> Hit Pattern</center></h5>\n"; 
  print $fsut "        </td>\n";
  print $fsut "        <td>\n";
  print $fsut "         <h5><center> Positions</center></h5>\n"; 
  print $fsut "        </td>\n";
  print $fsut "      </tr>\n";

  my $header;
  my $qtde=0;
  while ((read $fin, $char, 1) != 0) {
    if ($char eq ">") {
      $header = read_header($fin);
    }
    else
    {
      seek($fin, tell($fin) - 1, 0);
      my $sequence = read_sequence($fin);

      my $result = process_sequence($sequence);

      if ($result ne "") {
        $qtde = $qtde + 1;
        print $fout "    <div class=\"gene\">";
        print $fout "      <pre>$header\n$result</pre>\n";
        print $fout "    </div>\n";

        print $fsut "      <tr>\n";
        print $fsut "        <td>\n";
        print $fsut "          $header\n"; 
        print $fsut "        </td>\n";

        print $fsut "        <td>\n";
        print $fsut "          <table border=\"1\" width=\"100%\">\n"; 

        print $fsut "            <tr>\n";
        print $fsut "              <td>\n";
        print $fsut "                Name\n"; 
        print $fsut "              </td>\n";
        print $fsut "              <td>\n";
        print $fsut "                Match\n"; 
        print $fsut "              </td>\n";
        print $fsut "              <td>\n";
        print $fsut "                Mismatch\n";
        print $fsut "              </td>\n";
        print $fsut "              <td>\n";
        print $fsut "                Strand\n"; 
        print $fsut "              </td>\n";
        print $fsut "            </tr>\n";

        foreach my $p (@all_patterns) {
          my $summary = $p->get_summary();

          foreach my $s (@$summary) {
            print $fsut "            <tr>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $p->get_label() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_match() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_mismatch_num() . "\n";
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                +\n"; 
            print $fsut "              </td>\n";
            print $fsut "            </tr>\n";
          }

          $summary = $p->get_summary_comp();

          foreach my $s (@$summary) {
            print $fsut "            <tr>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $p->get_label() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_match() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_mismatch_num() . "\n";
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                -\n"; 
            print $fsut "              </td>\n";
            print $fsut "            </tr>\n";
          }
        }

        print $fsut "          </table>\n"; 
        print $fsut "        </td>\n";
        
        print $fsut "        <td>\n";
        print $fsut "          <table border=\"1\" width=\"100%\">\n"; 

        print $fsut "            <tr>\n";
        print $fsut "              <td>\n";
        print $fsut "                Start\n"; 
        print $fsut "              </td>\n";
        print $fsut "              <td>\n";
        print $fsut "                End\n"; 
        print $fsut "              </td>\n";
        print $fsut "            </tr>\n";


        foreach my $p (@all_patterns) {
          my $summary = $p->get_summary();

          foreach my $s (@$summary) {
            print $fsut "            <tr>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_start() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_end() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "            </tr>\n";
          }

          $summary = $p->get_summary_comp();

          foreach my $s (@$summary) {
            print $fsut "            <tr>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_start() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "              <td>\n";
            print $fsut "                " . $s->get_end() . "\n"; 
            print $fsut "              </td>\n";
            print $fsut "            </tr>\n";
          }
        }

        print $fsut "          </table>\n"; 
        print $fsut "        </td>\n";
        print $fsut "      </tr>\n";
        print $flist "$header\n";
      }
    }
  }
  print $fout "  </body>\n</html>\n";
  print $fsut "    </table>\n";
  print $fsut "<br> Number of targets sequences: $qtde\n"; 
  print $fsut " </body>\n</html>\n";
  

  close($fin);
  close($fout);
  close($fsut);
  close($flist);
}
