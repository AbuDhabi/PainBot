#!/usr/bin/perl

use Net::IRC;
use Math::Random::MT;
use Net::Ping::External;

$server = 'irc.yournet.net';
$port = 6667;
$channel = '#Your,#Channels,#Here';
$botnick = 'PainBot';
$botuname = 'painbot';
$password = 'foobar';
$botadmin = 'yournamehere';
$descript = 'AD\'s Other DiceBot';
$version = '0.42-07042014';
$maxline = 400;
$state = 0; # 1 connected, 0 disconnected

#$channel = '#test';
#$botnick = 'TestBot';

$gen = Math::Random::MT->new(localtime);
$irc = new Net::IRC;

$conn = $irc->newconn(Nick => $botnick,
                      Server => $server, 
                      Port => $port,
                      Username => $botuname,
                      Ircname => $descript);

$conn->add_global_handler('376', \&on_connect);
$conn->add_global_handler('disconnect', \&on_disconnect);
$conn->add_global_handler('kick', \&on_kick);
$conn->add_global_handler('msg', \&on_priv);
$conn->add_global_handler('cversion', \&on_ctcp_version);
$conn->add_global_handler('public', \&on_public);
$conn->add_global_handler('invite', \&on_invite);
$conn->add_global_handler('cjoin', \&on_ctcp_join);
$conn->add_global_handler('cpart', \&on_ctcp_part);

print STDERR "PainBot v".$version." started.\n";
#$irc->start;
# connect to IRC, add event handlers, etc.
$time_of_last_ping = $time_of_last_pong = time;
$irc->timeout(30);
# Can't handle PONG in Net::IRC (!), so handle "No origin specified" error
# (this may not work for you; you may rather do this some other way)
$conn->add_handler(409, sub { $time_of_last_pong = time });
while (1) {
    $irc->do_one_loop;
    # check internet connection: send PING to server
    if ( time-$time_of_last_ping > 30 ) {
        $conn->sl("PING"); # Should be "PING anything"
        $time_of_last_ping = time;
    }
    break if time-$time_of_last_pong > 90;
}
exit 1;

sub command_test {
   $self = shift;
   $args = shift;
   # add test code here

}

sub roll {
   $arg = shift;
   return int(1+$gen->rand($arg));
}

sub on_ctcp_join {
   $self = shift;
   $event = shift;
   foreach $arg ($event->args) {
      $chan = $arg;
      $self->join($chan);
      print STDERR "Joining $chan.\n";
   }
}

sub on_ctcp_part {
   $self = shift;
   $event = shift;
   foreach $arg ($event->args) {
      $self->part($chan);
      print STDERR "Parting $chan.\n";
   }
}

sub on_connect {
     $self = shift;
     $self->privmsg('nickserv', "identify $password");
     $self->join($channel);
     $state = 1;
     print STDERR "Connected to " . $server . ".\n";
}

sub on_disconnect {
   $self = shift;
   exit 1;
   print STDERR "Disconnected.\n";
   #$state = 0;
   #while ($state == 0) {
   #   $self->connect();
   #   sleep 30;
   #}
}

sub on_kick {
   $self = shift;
   $event = shift;
   print STDERR "Kicked by ".$event->nick.".\n";
}

sub on_priv {
   $self = shift;
   $event = shift;
   handle_message($self,$event,$event->nick);
}

sub on_public {
   $self = shift;
   $event = shift;
   handle_message($self,$event,$event->to);
}

sub handle_message {
   $self = shift;
   $event = shift;
   $dest = shift;

   foreach $arg ($event->args) {
      if ($arg =~ /^!die/i) {
         if ($event->nick eq $botadmin) {
            $self->quit("I return to the Wheel of Suffering.");
            print STDERR "Received shutdown command. Exiting.\n";
        	   exit 0;
         }
      } elsif ($arg =~ /^!live/i) {
         if ($event->nick eq $botadmin) {
            $self->privmsg($dest, 'I will return from the Wheel of Suffering.');
            print STDERR "Received reboot command. Restarting.\n";
        	   exec("/usr/bin/perl /home/abudhabi/painbot.pl") or die("Error: $!\n");
         }
      } elsif ($arg =~ /^!ping/i) {
         $self->privmsg($dest, 'pong!');
         print STDERR "Ping command activated by ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!version/i) {
         $self->privmsg($dest, 'PainBot v' . $version . ' by AnnoDomini.');
         print STDERR "Version command activated by ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!roll\s+/i) {
         $expression = substr($arg,6,$maxline);
         command_roll($self,$dest,$event->nick,$expression);
         print STDERR "Rolling $expression for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!help/i) {
         $expression =  substr($arg,6,$maxline);
         command_help($self,$dest,$event->nick,$expression);
         print STDERR "Help requested by ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!exalted\s+/i) {
         $expression = substr($arg,9,$maxline);
         dicepool_roll($self,$dest,$event->nick,"exalted",$expression);
         print STDERR "Rolling Exalted dice for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!sr3\s+/i) {
         $expression = substr($arg,5,$maxline);
         dicepool_roll($self,$dest,$event->nick,"sr3",$expression);
         print STDERR "Rolling SR3 dice for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!nwod\s/i) {
         $expression = substr($arg,6,$maxline);
         dicepool_roll($self,$dest,$event->nick,"nwod",$expression);
         print STDERR "Rolling nWoD dice for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!space\s+/i) {
         $expression = substr($arg,7,$maxline);
         dicepool_roll($self,$dest,$event->nick,"space",$expression);
         print STDERR "Rolling Space dice for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!twilight\s+/i) {
         $expression = substr($arg,10,$maxline);
         dicepool_roll($self,$dest,$event->nick,"twilight",$expression);
         print STDERR "Twilight 2013 roll for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!join\s+/i) {
         $expression = substr($arg,6,$maxline);
         command_join($self,$expression);
         print STDERR "Join request in $dest.\n";
      } elsif ($arg =~ /^!part\s+/i) {
         $expression = substr($arg,6,$maxline);
         command_part($self,$expression);
         print STDERR "Part request in $dest.\n";
      } elsif ($arg =~ /^!test\s+/i) {
         $expression = substr($arg,6,$maxline);
         command_test($self,$expression);
         print STDERR "Test request in $dest.\n";
      } elsif ($arg =~ /^!echo\s+/i) {
         $expression = substr($arg,6,$maxline);
         command_echo($self,$expression);
         print STDERR "Echo request in $dest.\n";
      } elsif ($arg =~ /^!fate/i) {
         $expression = substr($arg,6,$maxline);
         command_fate($self,$dest,$event->nick,$expression);
         print STDERR "Rolling Fate/FUDGE dice for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!fudge/i) {
         $expression = substr($arg,7,$maxline);
         command_fate($self,$dest,$event->nick,$expression);
         print STDERR "Rolling Fate/FUDGE dice for ".$event->nick." in $dest.\n";
      } elsif ($arg =~ /^!sr5/i) {
         $expression = substr($arg,5,$maxline);
         dicepool_roll($self,$dest,$event->nick,"sr5",$expression);
         print STDERR "Rolling SR5 dice for ".$event->nick." in $dest.\n";
      } else {
         if (is_shorthand($arg) == 1) {
            $expression = substr($arg,1,$maxline);
            command_roll($self,$dest,$event->nick,$expression);
            print STDERR "Rolling $expression for ".$event->nick." in $dest.\n";
         }
      }
   }
}

sub command_fate {
   $self = shift; 
   $dest = shift;
   $nick = shift;
   $args = shift;
   $output = "[$nick] rolled";
   $totals = "";
   if ($args =~ /:/) { 
      $colonpos = index $args,':';
      $comment = " \"".trim(substr($args,$colonpos+1,$maxline))."\"";
      $expression = substr($args,0,$colonpos);
   } else {
      $comment = "";
      $expression = $args;
   }
   $output .= "$comment: ";
   ($skill,$reps) = split(/ /,$expression);
   if (length($skill) == 0) { $skill = 0; }
   if ($skill < -2) { $skill = -2; }
   if ($skill > 8) { $skill = 8; }
   if (length($reps) == 0) { $reps = 1; }
   if ($reps < 0) { $reps = 1; }
   if ($reps > 30) { $reps = 30; }
   
   $lumped = "("; $results = "";
   for ($rep = 0;$rep<$reps;$rep++) {
      $temp = ""; $hits = $skill;
      for ($i = 0;$i<4;$i++) {
        $current = roll(3);
        if ($current == 1) { $temp .= "-" ; $hits--; }
        elsif ($current == 2) { $temp .= "O" ; }
        elsif ($current == 3) { $temp .= "+" ; $hits++; }
      }
      if ($hits < -2) { $adj = $hits +2; $verbal = "Terrible".$adj; }
      elsif ($hits == -2) { $verbal = "Terrible"; }
      elsif ($hits == -1) { $verbal = "Poor"; }
      elsif ($hits == 0) { $verbal = "Mediocre"; }
      elsif ($hits == 1) { $verbal = "Average"; }
      elsif ($hits == 2) { $verbal = "Fair"; }
      elsif ($hits == 3) { $verbal = "Good"; }
      elsif ($hits == 4) { $verbal = "Great"; }
      elsif ($hits == 5) { $verbal = "Superb"; }
      elsif ($hits == 6) { $verbal = "Fantastic"; }
      elsif ($hits == 7) { $verbal = "Epic"; }
      elsif ($hits == 8) { $verbal = "Legendary"; }
      elsif ($hits > 8) { $adj = $hits -8; $verbal = "Legendary+".$adj; }
      $lumped .= $temp . " ";
      if ($reps > 15) {
        $results .= $hits . "; ";
      } else {
        $results .= $hits . " ($verbal); ";
      }
   }
   $lumped = substr($lumped,0,-1) . ")";
   $results = substr($results,0,-2);
   
   $output .= $lumped . ". Results: \x02". $results . "\x02.";

   $self->privmsg($dest, $output);
    
}

sub command_echo {
   $self = shift;
   $args = shift;
   $self->privmsg($dest, $args);
}

sub command_help {
   $self = shift; 
   $dest = shift;
   $nick = shift;
   $topic = shift;
   if (length($topic) == 0) { 
      $output = "You have reached the help function of the PainBot, v$version, by AnnoDomini. Topics covered: general, roll, exalted, sr3, sr5, nwod, space, twilight, fate. The bot has some undocumented features.";
   } else {
      $output = "No manual entry found.";
   }
   if ($topic =~ /general/i) {
      $output = "In the dicepool-using commands, repetitions are capped at 30, while dice are capped at 200. In the generic roller, repetitions are capped at 30, and dice are capped at 1000. In both, automatic detail-hiding is in effect if the result would cause a flood. Uses a Mersenne Twister for random numbers.";
   }
   if ($topic =~ /roll/i) {
      $output = "The generic dice roller function. Flags: h (drop high), l (drop low), f (floating reroll). Syntax: !roll <dice expression>[flags][,repetitions][:comment]";
   }
   if ($topic =~ /exalted/i) {
      $output = "The Exalted 2e dice roller function. Flags: a, b, l, m (10s don't count double), f (subtracts 1 die from each successive roll). Syntax: !exalted <dice pool> [<target number> [<repetitions> [<external modifier>]]][:comment]";
   }
   if ($topic =~ /sr3/i) {
      $output = "The Shadowrun 3e dice roller function. Syntax: !sr3 <dice pool> [<target number> [<repetitions>]][:comment]";
   }
   if ($topic =~ /sr5/i) {
      $output = "The Shadowrun 5e dice roller function. Flags: f (sixes explode). Syntax: !sr5 <dice pool><flag> [<limit> [<repetitions>]][:comment]";
   }
   if ($topic =~ /nwod/i) {
      $output = "The New World of Darkness dice roller function. Flags: c (chance roll), n (no floating reroll). Syntax: !nwod <dice pool>[flags] [repetitions][:comment]";
   }
   if ($topic =~ /space/i) {
      $output = "The dice roller function for Reiver's Space Game. Syntax: !space <dice pool>[d<target number>+][,<repetitions>][:comment]";
   }
   if ($topic =~ /twilight/i) {
      $output = "Twilight 2013 dice roller function. Uses d16s instead of d20s. Flags: h (take highest), l (take lowest). Syntax: !twilight <dice pool><flag> [<target number> [<repetitions>]][:comment]";
   }
   if ($topic =~ /fate/i || $topic =~ /fudge/i) {
      $output = "Fate dice roller. Can be used for FUDGE but uses the FATE ladder. Syntax: <!fate | !fudge> <skill> [<repetitions>][:comment]";
   }
   $self->privmsg($dest, $output);
}

sub is_shorthand { # needs more detections
   $input = shift;
   if ($input =~ /^!d/i) { return 1; }
   if ($input =~ /^!\d/i) { return 1; }
   if ($input =~ /^!\(/i) { return 1; }
   return 0;
}

sub command_part {
   $self = shift;
   $chan = shift;
   $self->part($chan);
   print STDERR "Parting " . $chan . ".\n";
}

sub command_join {
   $self = shift;
   $chan = shift;
   $self->join($chan);
   print STDERR "Joining " . $chan . ".\n";
}

sub on_ctcp_version {
   $self = shift;
   $event = shift;
   $self->ctcp_reply($event->nick,'PainBot v' . $version . ' by AnnoDomini.');
   print STDERR "Received and replied to CTCP VERSION from " . $event->nick . ".\n";
}

sub dicepool_roll {
   $self = shift; 
   $dest = shift;
   $nick = shift;
   $ruleset = shift;
   $args = shift;
   $output = "[$nick] rolled ";
   if ($args =~ /:/) {
      $colonpos = index $args,':';
      $comment = "\"". trim(substr($args,$colonpos+1,$maxline)) ."\": ";
      $dicepoolexpression = substr($args,0,$colonpos);
   } else {
      $comment = "";
      $dicepoolexpression = $args;
   }
   if ($ruleset =~ /exalted/i) {
      ($dice,$tn,$reps,$ext) = split(/ /,$dicepoolexpression);
      if (($dice =~ /a/i) || ($dice =~ /b/i) || ($dice =~ /l/i) || ($dice =~ /m/i)) {
         $tensexplode = 0;
      } else {
         $tensexplode = 1;
      }
      if ($dice =~ /f/i) { $flurry = 1; } else { $flurry = 0; }
      if (length($tn) == 0) { $tn = 7; }
      if ($tn < 1) { $tn = 1; }
      if ($tn > 10) { $tn = 10; }
      if (length($ext) == 0) { $ext = 0; }
   } elsif ($ruleset =~ /nwod/i) {
      ($dice,$reps) = split(/ /,$dicepoolexpression);
      if ($dice =~ /n/) { $tensexplode = 0; } else { $tensexplode = 1; }
      if ($dice =~ /c/) { $tn = 10; } else { $tn = 8; }
   } elsif ($ruleset =~ /sr3/i) {
      ($dice,$tn,$reps) = split(/ /,$dicepoolexpression);
      if (length($tn) == 0) { $tn = 4; }
      if ($tn < 1) { $tn = 2; }
   } elsif ($ruleset =~ /sr5/i) {
      ($dice,$limit,$reps) = split(/ /,$dicepoolexpression);
      $tn = 5;
      if (length($limit) == 0) { $limit = "-"; }
      if ($limit < 0) { $limit = "-"; }
      if ($dice =~ /f/) { $sixesexplode = 1; } else { $sixesexplode = 0; }
   } elsif ($ruleset =~ /space/i) {
      ($dice, $tn, $reps) = $dicepoolexpression =~ /(\d+)(?:d(?:(\d+)\+)?)?(?:,(\d+))?/;
      #($dice,$tn,$reps) = split(/ /,$dicepoolexpression);
      $sixesexplode = 1;
      if (length($tn) == 0) { $tn = 4; }
      if (length($reps) == 0) { $reps = 1; }
      if (length($dice) == 0) { $dice = 1; }
      if ($tn < 1) { $tn = 1; }
      if ($tn > 6) { $tn = 6; }
   } elsif ($ruleset =~ /twilight/i) {
      ($dice,$tn,$reps) = split(/ /,$dicepoolexpression);
      if ($dice =~ /l/i) {
         $takelowest = 1;
      } elsif ($dice =~ /h/i) {
         $takelowest = 0;
      } else {
         $takelowest = 1;
      }
      if (length($tn) == 0) { $tn = 6; }
      if ($tn < 1) { $tn = 1; }
      if ($tn > 20) { $tn = 20; }
   }
   $dice =~ s/a//ig;   $dice =~ s/m//ig;   $dice =~ s/l//ig;   $dice =~ s/b//ig; $dice =~ s/f//ig; #exalted
   $dice =~ s/n//ig; $dice =~ s/c//ig; #nwod
   $dice =~ s/f//ig; # sr5
   $temp = "("; $successes = ""; 
   $measure = ""; $bumps = -1; $worst = 0; # twilight
   if (($reps < 1) || (length($reps) == 0)) { $reps = 1; }
   if ($reps > 30) { $reps = 30; }
   if ($dice > 200) { $dice = 200; }
   if (($dice < 1) || (length($dice) == 0)) { $dice = 1; }
   if ($dice * $reps > $maxline / 3) { $snip = 1; } else { $snip = 0; }
   for ($rep = 0;$rep<$reps;$rep++) {
      $currentsuccesses = 0 + $ext;
      for ($die = 0;$die<$dice;$die++) {
         if ($ruleset =~ /exalted/i) {
            $current = roll(10);
            if ($current >= $tn) {
               $currentsuccesses++;
               if (($tensexplode == 1) && ($current == 10)) {
                  $currentsuccesses++;
               }
            }
            $temp = $temp . $current . " ";
         } elsif ($ruleset =~ /nwod/i) {
            if ($tensexplode == 1) {
               do {
                  $current = roll(10);
                  if ($current >= $tn) {
                     $currentsuccesses++;
                  }
                  $temp = $temp . $current . " ";
               } while ($current == 10);
            } else {
               $current = roll(10);
               if ($current >= $tn) {
                  $currentsuccesses++;
               }
               $temp = $temp . $current . " ";
            }
         } elsif ($ruleset =~ /sr3/i) {
            $current = 0;
            do {
               $now = roll(6);
               $current = $current + $now;
            } while ($now == 6);
            if ($current >= $tn) {
               $currentsuccesses++;
            }
            $temp = $temp . $current . " ";
         } elsif ($ruleset =~ /sr5/i) {
            if ($sixesexplode == 1) {
               do {
                  $current = roll(6);
                  if ($current >= $tn) {
                     $currentsuccesses++;
                  }
                  $temp = $temp . $current . " ";
               } while ($current == 6);
            } else {
               $current = roll(6);
               if ($current >= $tn) {
                  $currentsuccesses++;
               }
               $temp = $temp . $current . " ";
            }
         } elsif ($ruleset =~ /space/i) {
            if ($sixesexplode == 1) {
               do {
                  $current = roll(6);
                  if ($current >= $tn) {
                     $currentsuccesses++;
                  }
                  if ($current == 6) {
                     $temp = $temp . "\x02" . $current . "\x02 ";
                  } else {
                     $temp = $temp . $current . " ";
                  }
               } while ($current == 6);
            } else {
               $current = roll(6);
               if ($current >= $tn) {
                  $currentsuccesses++;
               }
               if ($current == 6) {
                  $temp = $temp . "\x02" . $current . "\x02 ";
               } else {
                  $temp = $temp . $current . " ";
               }
            }
         } elsif ($ruleset =~ /twilight/i) {
            $current = roll(16);
            if ($takelowest == 1) {
               if ($current <= $tn) {
                  if (length($measure) == 0) {
                     $measure = $tn-$current;
                  } elsif ($tn-$current >= $measure) {
                     $measure = $tn-$current;
                  }
                  $bumps++;               
               } else {
                  if (length($measure) == 0) {
                     $measure = $tn-$current;
                  } elsif ($tn-$current >= $measure) {
                     $measure = $tn-$current;
                  }
               }
            } else {
               if ($current > $worst) { $worst = $current; }
            }
            $temp = $temp . $current . " ";
         }
      }
      if ($ruleset =~ /twilight/i) {
         if ($measure < 0) { $bumps = 0; }
         if ($takelowest == 0) { $measure = $tn-$worst; $bumps = 0; }
         $measure = $measure + ($bumps * 2);
         $successes = $successes . $measure . "; ";
         $measure = ""; $bumps = -1; $worst = 0;
      } else {
         $successes = $successes . $currentsuccesses . "; ";
      }
      $temp = substr($temp,0,-1) . "; ";
      if ($flurry == 1 && $ruleset =~ /exalted/i) {
         $dice = $dice - 1;
      }
   }
   $temp = substr($temp,0,-2) . ")";
   if ($ruleset =~ /exalted/i) {
      if ($ext == 0) {
         $suxnote = "";
      } elsif ($ext > 0) {
         $suxnote = " +$ext";
      } else {
         $suxnote = " $ext";
      }
   }
   if ($snip == 1) {
      $temp = "(many dice)";
   }
   if ($ruleset =~ /exalted/i) {
      $output = $output . $comment . $temp . ". Successes (TN " . $tn . ")$suxnote = \x02" . substr($successes,0,-2) . "\x02.";      
   } elsif ($ruleset =~ /nwod/i) {
      $output = $output . $comment . $temp . ". Successes (TN " . $tn . ") = \x02" . substr($successes,0,-2) . "\x02.";
   } elsif ($ruleset =~ /sr3/i) {
      $output = $output . $comment . $temp . ". Successes (TN " . $tn . ") = \x02" . substr($successes,0,-2) . "\x02.";
   } elsif ($ruleset =~ /sr5/i) {
      $output = $output . $comment . $temp . ". Successes = \x02" . substr($successes,0,-2) . "\x02 (limit " . $limit . ").";
   } elsif ($ruleset =~ /space/i) {
      $output = $output . $comment . $temp . ". Successes (TN " . $tn . ") = \x02" . substr($successes,0,-2) . "\x02.";
   } elsif ($ruleset =~ /twilight/i) {
      $output = $output . $comment . $temp . ". Margin(s) (TN " . $tn . ") = \x02" . substr($successes,0,-2) . "\x02.";
   }

   $self->privmsg($dest,$output);
}

sub command_roll {
   $self = shift; 
   $dest = shift;
   $nick = shift;
   $args = shift;
   $output = "[$nick] rolled ";
   $totals = "";
   if ($args =~ /:/) { 
      $colonpos = index $args,':';
      $comment = trim(substr($args,$colonpos+1,$maxline));
      $expressionwithreps = substr($args,0,$colonpos);
   } else {
      $comment = $args;
      $expressionwithreps = $args;
   }
   $output .= "\"$comment\": ";
   if ($expressionwithreps =~ /,/) {
      $commapos = index $expressionwithreps,',';
      $repetitions = eval(parse_one_roll(alltrim(substr($expressionwithreps,$commapos+1,$maxline))));
      print STDERR "$repetitions\n";
      $expression = alltrim(substr($expressionwithreps,0,$commapos));
   } else {
      $repetitions = 1;
      $expression = alltrim($expressionwithreps);
   }
   $expression =~ s/\^/\*\*/ig; # legacy
   if ($repetitions < 0) { $repetitions = 1; }
   if ($repetitions > 30) { $repetitions = 30; }
   $explength = length($expression);
   $expcopy = $expression;
   $mathableresult = "";
   for ($rep = 0;$rep<$repetitions;$rep++) { # rep loop
      $lastoperator = -1;
      for ($pos = 0;$pos<$explength;$pos++) { # string parsing
         $curchar = substr($expression,$pos,1);
         if (is_operator($curchar) == 1 || $pos == $explength-1) {
            if ($pos == $explength-1) {
               $mathableresult .= parse_one_roll(substr($expression,$lastoperator+1,$maxline));
            } else {
               $mathableresult .= parse_one_roll(substr($expression,$lastoperator+1,$pos-$lastoperator-1)) . $curchar;
            }
            $lastoperator = $pos;
         }
      }
      $output .= "$mathableresult, ";
      $totals .= eval($mathableresult)." ";
      $mathableresult = "";
   }
   $output = substr($output,0,-2).". Total: \x02".substr($totals,0,-1)."\x02.";

   $self->privmsg($dest, $output);
    
}

sub is_operator {
   $input = shift;
   if ($input eq '+') { return 1; }
   if ($input eq '-') { return 1; }
   if ($input eq '*') { return 1; }
   if ($input eq '/') { return 1; }
   if ($input eq '^') { return 1; }
   if ($input eq '%') { return 1; }
   if ($input eq '(') { return 1; }
   if ($input eq ')') { return 1; }
   return 0;
}

sub parse_one_roll {
   $args = shift;
   $dpos = index lc($args),'d';
   if ($dpos == -1) { return $args; }
   if ($args =~ /l/i) { # l
      $droplow = 1;
      $args =~ s/l//ig;
   } else {
      $droplow = 0;
   }
   if ($args =~ /h/i) { # h
      $drophigh = 1;
      $args =~ s/h//ig;
   } else {
      $drophigh = 0;
   }
   if ($args =~ /f/i) { # f
      $floating = 1;
      $args =~ s/f//ig;
   } else {
      $floating = 0;
   }
   if ($dpos == 0) { 
      $nrofdice = 1;
   } else {
      $nrofdice = substr($args,0,$dpos);
      if ($nrofdice == 0) {
         $nrofdice = 1;         
      }
      if ($nrofdice > 1000) {
         $nrofdice = 1000;
      }
   }
   $diesize = substr($args,$dpos+1,$maxline);
   if ($nrofdice * length($diesize) > ($maxline / 3)) {
      $snip = 1;
   } else {
      $snip = 0;
   }
   $result = '('; $highest = 0; $lowest = $diesize+1;
   for ($i = 0;$i<$nrofdice;$i++) {
      do {
         $current = roll($diesize);
         if (($droplow == 1) && ($current < $lowest)) { $lowest = $current; }
         if (($drophigh == 1) && ($current > $highest)) { $highest = $current; }
         $result .= $current . '+';
      } while (($current == $diesize) && ($floating == 1));
   }
   $result = substr($result,0,-1);
   if ($droplow == 1) { $result = $result."-$lowest"; }
   if ($drophigh == 1) { $result = $result."-$highest"; }
   $result = $result.')';
   if ($snip == 0) {
      return $result;
   } else {
      return eval($result);
   }
}

sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub ltrim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}

sub rtrim($) {
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub alltrim($) {
   my $string = shift;
   $string =~ s/\s+//g;
   return $string;
}

sub one_shift {
   $shifted = shift;
   return $shifted;
}

sub on_invite {
   $self = shift;
   $event = shift;
   $chan = one_shift($event->args);
   $self->join($chan);
   print STDERR "Received invite from " . $event->nick . " to ".$chan.". Joining.\n";
}
