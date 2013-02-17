#!/usr/bin/perl

use strict;
use warnings;

package State;

my %COMPLEMENT = ( "A" => "T",
                   "C" => "G",
                   "G" => "C",
                   "T" => "A",
                   "N" => "N",
                   "[" => "]",
                   "]" => "[",
                   "(" => ")",
                   ")" => "(",
                   "-" => "-"
                 );

sub new
{
  my $class = shift;
  my $self = {
    _token           => shift,
    _accept_mismatch => 1,
    _next_states     => {},
  };

  bless $self, $class;
  return $self;
}

sub set_token
{
  my ($self, $token) = @_;

  $self->{_token} = $token if defined($token);
  return $self->{_token};
}

sub get_token
{
  my ($self) = @_;

  return $self->{_token};
}

sub set_accept_mismatch
{
  my ($self, $accept_mismatch) = @_;

  $self->{_accept_mismatch} = $accept_mismatch if defined($accept_mismatch);
  return $self->{_accept_mismatch};
}

sub get_accept_mismatch
{
  my ($self) = @_;

  return $self->{_accept_mismatch};
}

sub add_next_state
{
  my ($self, $next_state) = @_;

  $self->{_next_states}->{$next_state->get_token()} = $next_state;
 
  return $self->{_next_states};
}

sub get_next_states 
{
  my ($self) = @_;
  return \$self->{_next_states};
}

sub generate_graph
{
  my $pattern    =  $_[0];

  die "Invalid token on the expression" if $pattern =~ m/\-/;

  $pattern =~ s/\]\[/\]-\[/g;

  my @el   = split //, $pattern;

  my $is_bracket     = 0;
  my $is_parenthesis = 0;

  my $start_state = new State();
  my $curr_state = $start_state;
  $start_state->set_token("<start>");

  my $next_state;
  my $consume_state = 1;
  while ($#el >= 0) {
    my $char = shift(@el);
    if ($char eq "[") {
      die "Not allowed bracket inside bracket" if $is_bracket;

      $is_bracket = 1;
    }
    elsif ($char eq "]") {
      die "Closing bracket without opening" if $is_bracket == 0;
      my $size += keys  %${$curr_state->get_next_states()};
      die "Not enough elements inside the bracket" if $size < 2;

      $is_bracket = 0;
      $consume_state = 0;
    }
    elsif ($char eq "(") {
      die "Cannot have a parenthesis inside a bracket" if $is_bracket;
      $is_parenthesis = 1;
    }
    elsif ($char eq ")") {
      die "Closing parenthesis without opening" if $is_parenthesis == 0;
      $is_parenthesis = 0;
    }
    elsif (exists $COMPLEMENT{$char}) {
      if ($is_bracket) {
        my $tmp_state = new State();
        $tmp_state->set_token($char);
        my $mismatch = 0 if $is_parenthesis == 1;
        $tmp_state->set_accept_mismatch($mismatch);
        $curr_state->add_next_state($tmp_state);
      }
      else {
        my $tmp_state = new State();
        $tmp_state->set_token($char);
        my $mismatch = 0 if $is_parenthesis == 1;
        $tmp_state->set_accept_mismatch($mismatch);

        if ($consume_state)
        {
          $curr_state->add_next_state($tmp_state);
        }
        else
        {
          $consume_state = 1;
          for my $el (keys %${$curr_state->get_next_states()}) {
            ${${$curr_state->get_next_states()}}{$el}->add_next_state($tmp_state);
          }
        }

        $curr_state = $tmp_state; 
      }
    }
    else {
      die "Invalid token on the expression";
    }
  }

  die "Bracket not closed" if $is_bracket;

  return $start_state;
}

sub print_graph
{
  my $str        = $_[0];
  my $curr_state = $_[1];

  my $size += keys %${$curr_state->get_next_states()};

  if ($size == 0) {
    print $str . "<end>\n";
  }

  for my $el (keys %${$curr_state->get_next_states()}) {
    if ($el ne "-")
    {
      print_graph($str . $el, ${${$curr_state->get_next_states()}}{$el});
    }
    else
    {
      print_graph($str, ${${$curr_state->get_next_states()}}{$el});
    }
  }
}

sub check_state
{
  my $char         = $_[0];
  my $curr_state   = $_[1];
  my $num_mismatch = $_[2];

  die "UNDEFINED" if !defined $char;

  if (exists ${${$curr_state->get_next_states()}}{"-"}) {
    return check_state($char, ${${$curr_state->get_next_states()}}{"-"}, $num_mismatch);
  }
  if (exists ${${$curr_state->get_next_states()}}{$char}) {
    return (1, ${${$curr_state->get_next_states()}}{$char}, $num_mismatch);
  }
  elsif ($num_mismatch) {
    my $size += keys %${$curr_state->get_next_states()};
    if ($size) {
      my $char = [keys %${$curr_state->get_next_states()}]->[0];
      if (${${$curr_state->get_next_states()}}{$char}->get_accept_mismatch()) {
        return (1, ${${$curr_state->get_next_states()}}{$char}, $num_mismatch - 1);
      }
    }
  }

  return (0, 0, 0);
}

1;
