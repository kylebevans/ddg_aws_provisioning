#!/usr/bin/env perl

use local::lib;
use Paws;
use Data::Printer;


# read in the cloudformation template
my $file = "ddg.tpl";
my $cftemplate;
{
    local $/;
    open my $fh, '<', $file or die "can't open $file: $!";
    $cftemplate = <$fh>;
}


# create the stack in us-east-2
my $cfddg = Paws->service('CloudFormation', region => 'us-east-2') or die "can't create CloudFormation object: $!";

@parameters = { ParameterKey => "KeyName", ParameterValue => "kylebe-key-pair-useast2" };

$parameters_ref = \@parameters;

my $stackoutput = $cfddg->CreateStack(
  Parameters => $parameters_ref,
  StackName => "ddgstack",
  TemplateBody => $cftemplate
) or die "stack creation failed: $!";

my $stackid = $stackoutput->StackId;

# Show stack events during stack creation process.
# Stack creation is asynchronous, so you have to keep running
# DescribeStackEvents to keep getting the events until the stack creation
# is complete or the rollback is complete in the event of failure.
# However, that also means you get the old events again, so this keeps
# a hash of all the events gotten over time and doesn't print duplicates.
# DescribeEvents is also paginated, so you have to get the first page, process it,
# then loop through all of the other pages if they exist and process them.
# change so it checks for keys and values bc only one subnet shows
my %eventlist;
while (!('CREATE_COMPLETE AWS::CloudFormation::Stack' ~~ [keys %eventlist]) && !('ROLLBACK_COMPLETE AWS::CloudFormation::Stack' ~~ [keys %eventlist])) {
  # process first page of events
  my $stackevents = $cfddg->DescribeStackEvents(StackName => $stackid);
  foreach $stackevent ($stackevents->StackEvents) {
    $stackeventobj = shift @$stackevent;
    $rstatus = $stackeventobj->ResourceStatus;
    $rtype = $stackeventobj->ResourceType;
    $lrid = $stackeventobj->LogicalResourceId;
    $eventlistmember = $rstatus . " " . $rtype . " " . $lrid;
    if (!($eventlistobj ~~ @eventlist)) {
      push @eventlist, $eventlistmember;
      print $eventlistmember . "\n";
    }
  }
  # process the rest of the pages of events if they exist
  while ($stackevents->NextToken) {
    $stackevents = $cfddg->DescribeStackEvents(StackName => $stackid, NextToken => $stackevents->NextToken);
    foreach $stackevent ($stackevents->StackEvents) {
      $stackeventobj = shift @$stackevent;
      $rstatus = $stackeventobj->ResourceStatus;
      $rtype = $stackeventobj->ResourceType;
      $lrid = $stackeventobj->LogicalResourceId;
      $eventlistmember = $rstatus . " " . $rtype . " " . $lrid;
      if (!($eventlistobj ~~ @eventlist)) {
        push @eventlist, $eventlistmember;
        print $eventlistmember . "\n";
      }
    }
  }
}

