//***********************************************************************
// Copyright         : 2023 Alex Ternovoy
// File Name         : blackjack.q
// Description       : This file contains the logic of the blackjack game
//***********************************************************************

\d .blackjack

// Seed for random deck shuffling
system"S ",string sum "J"$9 cut reverse string .z.i+"j"$.z.P

// Constants
CARDSYMBOLS:`2`3`4`5`6`7`8`9`10`J`Q`K`A
CARDSUITS:`Diamond`Heart`Club`Spade
SUITSSYMBOLS:CARDSUITS!("♦";"♥";"♣";"♠")

FACECARDS:`J`Q`K`A
FACECARDSVALUE:`10

POINTSLIMIT:21

UIHIDDENCARD:("┌─────────┐ ";
              "│░░░░░░░░░| ";
              "│░░░░░░░░░| ";
              "|░░░░░░░░░| ";
              "|░░░░░░░░░| ";
              "|░░░░░░░░░| ";
              "|░░░░░░░░░| ";
              "|░░░░░░░░░| ";
              "└─────────┘ ");

// Game state variables
ChipsBalance:2
Deck:()
DealerHand:()
PlayerHand:()
PlayerTurnEnd:0b;
DealerTurnEnd:0b;

// Functions

// Permute cards for random order
shuffle:{[deck] 0N?deck}  

// Deck format:
// 4  Diamond
// 6  Spade  
// 3  Heart
// ...
createDeck:{raze CARDSYMBOLS cross\: CARDSUITS}

// Take x cards from the deck, update deck, so these can't be taken twice
drawCards:{
  cards:x#Deck;
  `Deck set x _ Deck;
  cards}

// cards have a format:
// 3 Heart  
// 7 Diamond
// ...
calculateScore:{[cards]
  cardValues:cards[;0];
  isPlayer:cards~PlayerHand;
  
  // Dealer shows only one card during the dealer turn, the another one is hidden, 
  // so we temporary exclude it from calculation
  cardValues:$[PlayerTurnEnd or isPlayer;cardValues; 1_cardValues];
  
  // If card is face card - count if for 10, otherwise use card value
  score:sum "I"$string[?[cardValues in FACECARDS;FACECARDSVALUE;cardValues]];  
  
  // If we have Ace in hand it can be counted as 10 or 1, depends on the total number of points
  // So if we don't have Ace we just use "score" variable, otherwise we count it as 10 if hand is smaller 21
  // Or as 1 if player got score >21, that means "score-10+1" or equivalent "score-9"
  res:(score;$[POINTSLIMIT<=score;score-9;score])`A in cardValues;
  res} 

uiCard:{[card]
  cardSymbol:first card;
  cardSuite:last card;

  topIndent:6;
  cardSuiteIndent:7;
  bottomIndent:-6;

  // Adding shift to properly display layout for top symbol(ts), bottom symbol(bs) and suite(s)
  ts:topIndent$string cardSymbol;
  s:cardSuiteIndent$SUITSSYMBOLS[cardSuite];
  bs:bottomIndent$string cardSymbol;
  ascii:( "┌─────────┐ ";
          "│",ts,"   | ";
          "│         | ";
          "│         | ";
          "|    ",s,"| ";
          "|         | ";
          "|         | ";
          "|   ",bs,"| ";
          "└─────────┘ ");
  ascii};

displayCards:{[cards]
  isPlayer:cards~PlayerHand;                                // Dealer shows only one card during the dealer turn, the another one is hidden
  ascii:$[PlayerTurnEnd or isPlayer;
      " " ,'/ uiCard each cards;                            // Creating list of ascii cards, join each to show them in a row
      " " ,'/ (enlist UIHIDDENCARD), 1_(uiCard each cards)  // Replacing first card with hidden card for dealer
      ];
  ascii}

showUI:{[]
  -1 "====================DEALER====================";
  -1 "  Dealer must stand on a 17 and draw to 16";
  -1 "==============================================";
  -1 displayCards[DealerHand];
  -1 "Dealer score ", string[calculateScore[DealerHand]],"\n";

  -1 "====================PLAYER====================";
  -1 "  Your balance: ", string[ChipsBalance]," chips";
  -1 "==============================================";
  -1 displayCards[PlayerHand];
  -1 "Player score ", string[calculateScore[PlayerHand]],"\n";
  }

dealerTurn:{
  while[calculateScore[DealerHand]<17; // Dealer must stand on a 17 and draw to 16
      `DealerHand set DealerHand, drawCards[1];
      ];
  `DealerTurnEnd set 1b;
  }

hit:{
  `PlayerHand set PlayerHand, drawCards[1]; 
  showUI[]
  }

stand:{
  `PlayerTurnEnd set 1b;
  dealerTurn[]; 
  showUI[]
  }

// Update chips balance and print draw results
updateStatus:{[chipsBalanceDelta;msg]                                                         
  `ChipsBalance set ChipsBalance+chipsBalanceDelta; 
  -1 msg;
  sign:$[chipsBalanceDelta>=0;"+";"-"];
  -1 "Your new balance: ", string[ChipsBalance], " chips (", sign, string[abs chipsBalanceDelta],")";
  }

exitGame:{exit 0}

startNewGame:{
  `PlayerTurnEnd`DealerTurnEnd set' 0b;
  `Deck set shuffle createDeck[];

  `DealerHand`PlayerHand set' (drawCards[2];drawCards[2]); // Deal 2 cards to the player and the dealer

  showUI[];

  while[(calculateScore[PlayerHand]<=POINTSLIMIT) and (DealerTurnEnd<>1b);
      -1 "Hit (h) or Stand (s)?";
      action:`$read0 0;

      playerActions:`h`s!(hit;stand);
      if[not action in key playerActions; -1 "Unknown action! Choose Hit (h) or Stand (s)"];

      playerActions[action][]
  ];

  playerScore:calculateScore[PlayerHand];
  dealerScore:calculateScore[DealerHand];

  $[playerScore>POINTSLIMIT; [updateStatus[-1;"You are busted!"]];
      dealerScore>POINTSLIMIT; [updateStatus[1;"Win! Dealer busts"]];
      playerScore=dealerScore; [updateStatus[0;"Push... equal score"]];
      playerScore<dealerScore; [updateStatus[-1;"Loose... Dealer has the best score"]];
      [updateStatus[1;"Win! Dealer busts"]] // Default CASE value if playerScore > dealerScore
  ];

  if[ChipsBalance=0; -1 "You no longer have chips. Game over!"; exitGame[]];
  showMenu[]
  }

showMenu:{
  -1 "====================MENU====================";
  -1 "  New game? (n)";
  -1 "  Exit (e)";
  menuChoice:`$read0 0;

  menuActions:`n`e!(startNewGame;exitGame);
  if[not menuChoice in key menuActions; -1 "Unknown command! Choose New game (n) or Exit (e)";];

  menuActions[menuChoice][];
  }

showMenu[]