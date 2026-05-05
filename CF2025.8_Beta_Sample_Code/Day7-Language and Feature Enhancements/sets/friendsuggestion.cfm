<cfscript>
// User's direct friends
userFriends = SetNew();
userFriends.add("Alice");
userFriends.add("Bob");
userFriends.add("Charlie");

// Friends of friends
aliceFriends = SetNew();
aliceFriends.add("Bob");
aliceFriends.add("David");
aliceFriends.add("Eve");

bobFriends = SetNew();
bobFriends.add("Alice");
bobFriends.add("Frank");
bobFriends.add("Grace");

charlieFriends = SetNew();
charlieFriends.add("Alice");
charlieFriends.add("David");
charlieFriends.add("Henry");

// Collect all friends of friends
friendsOfFriends = SetNew();
for (friend in userFriends) {
    if (friend == "Alice") {
        friendsOfFriends = setUnion(friendsOfFriends, aliceFriends);
    } else if (friend == "Bob") {
        friendsOfFriends = setUnion(friendsOfFriends, bobFriends);
    } else if (friend == "Charlie") {
        friendsOfFriends = setUnion(friendsOfFriends, charlieFriends);
    }
}

// Suggestions: Friends of friends who aren't already friends
// AND not the user themselves
suggestions = setDifference(friendsOfFriends, userFriends);

writeOutput("Friend suggestions: " & setToList(suggestions, ", "));
// Output: "David, Eve, Frank, Grace, Henry"

// Find mutual friends for each suggestion (connection strength)
mutualFriendsCount = {};
for (suggestion in suggestions) {
    // Count how many of user's friends know this person
    mutualFriendsCount[suggestion] = 0;
    
    if (aliceFriends.has(suggestion) && userFriends.has("Alice")) {
        mutualFriendsCount[suggestion]++;
    }
    if (bobFriends.has(suggestion) && userFriends.has("Bob")) {
        mutualFriendsCount[suggestion]++;
    }
    if (charlieFriends.has(suggestion) && userFriends.has("Charlie")) {
        mutualFriendsCount[suggestion]++;
    }
}

writeDump(mutualFriendsCount);
// Suggestions sorted by mutual friend count for better recommendations
</cfscript>