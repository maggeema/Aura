import 'package:flutter/material.dart';

class AuraStreakPopup {
  static void show(BuildContext context, int streak) {
    final stageLabels = ["New Bean", "Wandering Turtle", "Curious Cat", "Owl of the House"];
    final avatarImages = [
      "assets/coffee_logo.png", // Default
      "assets/turtle.png",      // 7-day
      "assets/cat.png",         // 14-day
      "assets/owl.png",         // 30-day
    ];
    final streakRequirements = ["< 7 day streak", "7+ day streak", "14+ day streak", "30+ day streak"];
    final descriptions = [
      "Still settling into the blend — just starting to explore or keeping it casual without a regular rhythm (yet!)",
      "Taking their first steps into the cafe world — slow, steady, and sipping their way through new spots.",
      "Comfortable in cozy corners and always on the lookout for the next great cup — a frequent explorer with a nose for good brews.",
      "Wise in the ways of the cafe scene — a trusted voice whose thoughtful recommendations and rich experience guide the community."
    ];

    String currentLabel;
    String currentAvatar;
    if (streak >= 30) {
      currentLabel = stageLabels[3];
      currentAvatar = avatarImages[3];
    } else if (streak >= 14) {
      currentLabel = stageLabels[2];
      currentAvatar = avatarImages[2];
    } else if (streak >= 7) {
      currentLabel = stageLabels[1];
      currentAvatar = avatarImages[1];
    } else {
      currentLabel = stageLabels[0];
      currentAvatar = avatarImages[0];
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Your Aura Streak', style: TextStyle(color: Color(0xFF333333))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: AssetImage(currentAvatar),
                      radius: 40,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Current Streak: $streak day(s)',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
              Text(
                'What does your streak mean?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
              ),
              SizedBox(height: 12),
              ...List.generate(4, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(avatarImages[index]),
                        radius: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${stageLabels[index]} (${streakRequirements[index]})",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              descriptions[index],
                              style: TextStyle(color: Color(0xFF333333)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: Colors.deepPurple)),
          )
        ],
      ),
    );
  }
}
