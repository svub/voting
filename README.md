Voting
======

Short
-----
Voting/counting/rating/document-relation module for Meteor. Keep track of how many X point to or voted for Y, optionally, keep a list of all X._id in Y or a list of all Y._id in X, or both.

Long
----
Provides voting/rating/counting functionality for one item of a collection rating/counting an item of the same or different collection.
In this documentation, the word 'voting' is used, but if you want to count, e.g. how many docs of kind A refer to a doc of kind B, thencounting an A using B would be called A voting B. Guess that might be confusing, but this utility can simply be used for both and most likely more use cases and it started from being used for a using rating/voting on an item. Check the examples to get a better idea.
The basic function is to keep a count in B of how many As voted for B
Simultaneously, it can keep lists of
* raters/voters IDs in the voted item (who voted for this item)
* rated/voted item IDs in the voter (what items I voted for)
All fields are customizable.

Setup
-----
voting = new Meteor.Voting(name, target, source, fields)
name: name of collection to store the link object between source and target
target: collection of items to be rated/voted
source: collection voters/raters (optional)
fields: (optional)
  up               name of field in target/voted to store the count of up-votes ("thumb up")
  down             name of field in target/voted to store the count of down-votes ("thumb down")
  sourceListUp     name of field in source/voter to store the IDs of the item voted-down on
  sourceListDown   name of field in source/voter to store the IDs of the item voted-down on
  targetListUp     name of field in target/voted to store the IDs of the voters who voted this item down
  targetListDown   name of field in target/voted to store the IDs of the voters who voted this item down

The lists (arrays) are for convenience and efficiency, otherwise voting.getVoter(votedId) or voting.getVoted(voterId) can be used. Also, if fields is a string, the string will be the name for the "up" field

voting.vote(voter, voted, up, why)
  voter ID from the source collection
  voted ID from the target collection
  up    up or down vote (optional, default: up=true)
  why   string that can contain why a voter voted an item down (optional)

voting.unvote(voter, voted)
  removes any previous voting; see @vote

Use cases
---------
Report and approve items by users:
checkedItems = new Voting("checkedItems", items, Meteor.users, { up:"approved", down:"reported", sourceListDown:"reportedItems", sourceListUp:"approvedItems", targetListDown:"reportedBy", targetListUp:"approvedBy" }

Rate items by users
userVotes = new Voting("userVotes", Meteor.users)
will vote on Meteor.users collection; default fields are { up: "votesUp"; down: "votesDown" }

Counting the usage/reference of something (not using the "down vote" feature)
carOwners = new Voting("carOwners", cars, Meteor.users, { targetListUp: "owners", sourceListUp: "cars"}
