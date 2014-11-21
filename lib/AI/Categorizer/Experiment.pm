use strict;

package AI::Categorizer::Experiment;

use Class::Container;
use AI::Categorizer::Storable;
use Statistics::Contingency;

use base qw(Class::Container AI::Categorizer::Storable Statistics::Contingency);

use Params::Validate qw(:types);
__PACKAGE__->valid_params
  (
   categories => { type => ARRAYREF|HASHREF },
   sig_figs   => { type => SCALAR, default => 4 },
  );

sub new {
  my $package = shift;
  my $self = $package->Class::Container::new(@_);
  
  $self->{$_} = 0 foreach qw(a b c d);
  my $c = delete $self->{categories};
  $self->{categories} = { map {($_ => {a=>0, b=>0, c=>0, d=>0})} 
			  UNIVERSAL::isa($c, 'HASH') ? keys(%$c) : @$c
			};
  return $self;
}

sub add_hypothesis {
  my ($self, $h, $correct, $name) = @_;
  die "No hypothesis given to add_hypothesis()" unless $h;
  $name = $h->document_name unless defined $name;
  
  $self->add_result([$h->categories], $correct, $name);
}

sub stats_table {
  my $self = shift;
  $self->SUPER::stats_table($self->{sig_figs});
}

1;

__END__

=head1 NAME

AI::Categorizer::Experiment - Coordinate experimental results

=head1 SYNOPSIS

 use AI::Categorizer::Experiment;
 my $e = new AI::Categorizer::Experiment(categories => \%categories);
 my $l = AI::Categorizer::Learner->restore_state(...path...);
 
 while (my $d = ... get document ...) {
   my $h = $l->categorize($d); # A Hypothesis
   $e->add_hypothesis($h, [map $_->name, $d->categories]);
 }
 
 print "Micro F1: ", $e->micro_F1, "\n"; # Access a single statistic
 print $e->stats_table; # Show several stats in table form

=head1 DESCRIPTION

The C<AI::Categorizer::Experiment> class helps you organize the
results of categorization experiments.  As you get lots of
categorization results (Hypotheses) back from the Learner, you can
feed these results to the Experiment class, along with the correct
answers.  When all results have been collected, you can get a report
on accuracy, precision, recall, F1, and so on, with both
macro-averaging and micro-averaging over categories.

=head1 METHODS

The general execution flow when using this class is to create an
Experiment object, add a bunch of Hypotheses to it, and then report on
the results.

Internally, C<AI::Categorizer::Experiment> inherits from the
C<Statistics::Contingency>.  Please see the documentation of
C<Statistics::Contingency> for a description of its interface.  All of
its methods are available here, with the following additions:

=over 4

=item new( categories => \%categories )

=item new( categories => \@categories, verbose => 1, sig_figs => 2 )

Returns a new Experiment object.  A required C<categories> parameter
specifies the names of all categories in the data set.  The category
names may be specified either the keys in a reference to a hash, or as
the entries in a reference to an array.

The C<new()> method accepts a C<verbose> parameter which
will cause some status/debugging information to be printed to
C<STDOUT> when C<verbose> is set to a true value.

A C<sig_figs> indicates the number of significant figures that should
be used when showing the results in the C<results_table()> method.  It
does not affect the other methods like C<micro_precision()>.

=item add_result($assigned, $correct, $name)

Adds a new result to the experiment.  Please see the
C<Statistics::Contingency> documentation for a description of this
method.

=item add_hypothesis($hypothesis, $correct_categories)

Adds a new result to the experiment.  The first argument is a
C<AI::Categorizer::Hypothesis> object such as one generated by a
Learner's C<categorize()> method.  The list of correct categories can
be given as an array of category names (strings), as a hash whose keys
are the category names and whose values are anything logically true,
or as a single string if there is only one category.  For example, all
of the following are legal:

 $e->add_hypothesis($h, "sports");
 $e->add_hypothesis($h, ["sports", "finance"]);
 $e->add_hypothesis($h, {sports => 1, finance => 1});

=back

=cut
