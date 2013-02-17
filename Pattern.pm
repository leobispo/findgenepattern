#!/usr/bin/perl

package Pattern;

sub new
{
  my $class = shift;
  my $self = {
    _label         => undef,
    _min_match     => undef,
    _pattern       => undef,
    _summary       => undef,
    _summary_comp  => undef,
    _start         => undef,
    _end           => undef,
    _start_comp    => undef,
    _end_comp      => undef,
    _mismatch      => undef,
    _mismatch_comp => undef
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

sub set_min_match
{
  my ($self, $min_match) = @_;

  $self->{_min_match} = $min_match if defined($min_match);
  return $self->{_min_match};
}

sub get_min_match
{
  my ($self) = @_;

  return $self->{_min_match};
}

sub set_pattern
{
  my ($self, $pattern) = @_;

  $self->{_pattern} = $pattern if defined($pattern);
  return $self->{_pattern};
}

sub get_pattern
{
  my ($self) = @_;

  return $self->{_pattern};
}

sub set_summary
{
  my ($self, $summary) = @_;

  $self->{_summary} = $summary if defined($summary);
  return $self->{_summary};
}

sub get_summary
{
  my ($self) = @_;

  return $self->{_summary};
}

sub set_summary_comp
{
  my ($self, $summary_comp) = @_;

  $self->{_summary_comp} = $summary_comp if defined($summary_comp);
  return $self->{_summary_comp};
}

sub get_summary_comp
{
  my ($self) = @_;

  return $self->{_summary_comp};
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

sub set_start_comp
{
  my ($self, $start_comp) = @_;

  $self->{_start_comp} = $start_comp if defined($start_comp);
  return $self->{_start_comp};
}

sub get_start_comp
{
  my ($self) = @_;

  return $self->{_start_comp};
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

sub set_end_comp
{
  my ($self, $end_comp) = @_;

  $self->{_end_comp} = $end_comp if defined($end_comp);
  return $self->{_end_comp};
}

sub get_end_comp
{
  my ($self) = @_;

  return $self->{_end_comp};
}

sub set_mismatch
{
  my ($self, $mismatch) = @_;

  $self->{_mismatch} = $mismatch if defined($mismatch);
  return $self->{_mismatch};
}

sub get_mismatch
{
  my ($self) = @_;

  return $self->{_mismatch};
}

sub set_mismatch_comp
{
  my ($self, $mismatch_comp) = @_;

  $self->{_mismatch_comp} = $mismatch_comp if defined($mismatch_comp);
  return $self->{_mismatch_comp};
}

sub get_mismatch_comp
{
  my ($self) = @_;

  return $self->{_mismatch_comp};
}

1;
