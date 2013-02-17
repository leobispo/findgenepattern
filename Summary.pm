#!/usr/bin/perl

package Summary;

sub new
{
  my $class = shift;
  my $self = {
    _label        => undef,
    _match        => undef,
    _mismatch_num => 0,
    _start        => 0,
    _end          => 0,
 
  };

  bless $self, $class;
  return $self;
}

sub set_label
{
  my ($self, $label) = @_;

  $self->{_label} = $label if defined($label);
  return $self->{_label};
}

sub get_label
{
  my ($self) = @_;

  return $self->{_label};
}

sub set_match
{
  my ($self, $match) = @_;

  $self->{_match} = $match if defined($match);
  return $self->{_match};
}

sub get_match
{
  my ($self) = @_;

  return $self->{_match};
}

sub set_mismatch_num
{
  my ($self, $mismatch_num) = @_;

  $self->{_mismatch_num} = $mismatch_num if defined($mismatch_num);
  return $self->{_mismatch_num};
}

sub get_mismatch_num
{
  my ($self) = @_;

  return $self->{_mismatch_num};
}

sub set_start
{
  my ($self, $start) = @_;

  $self->{_start} = $start if defined($start);
  return $self->{_start};
}

sub get_start
{
  my ($self) = @_;

  return $self->{_start};
}

sub set_end
{
  my ($self, $end) = @_;

  $self->{_end} = $end if defined($end);
  return $self->{_end};
}

sub get_end
{
  my ($self) = @_;

  return $self->{_end};
}

1;
