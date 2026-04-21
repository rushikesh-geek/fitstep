class HealthArticle {
  final String title;
  final String category;
  final String description;
  final String youtubeUrl;

  HealthArticle({
    required this.title,
    required this.category,
    required this.description,
    required this.youtubeUrl,
  });
}

// Health articles data
final List<HealthArticle> healthArticles = [
  // Fitness Articles
  HealthArticle(
    title: 'How To Build A Daily Walking Habit',
    category: 'Fitness',
    description:
        'Walking is one of the simplest forms of exercise. Aim for 10,000 steps daily to maintain cardiovascular health.',
    youtubeUrl: 'https://www.youtube.com/watch?v=-3N2sUkdf-Y',
  ),
  HealthArticle(
    title: 'What is HIIT? 7 Proven HIIT Benefits and How to Do It Properly',
    category: 'Fitness',
    description:
        'HIIT workouts boost metabolism and improve endurance. Short bursts of intense activity followed by rest periods.',
    youtubeUrl: 'https://www.youtube.com/watch?v=dNJ2gG-Jud4',
  ),
  HealthArticle(
    title: 'Strength Training Benefits',
    category: 'Fitness',
    description:
        'Building muscle increases metabolic rate and improves bone density. Aim for 2-3 sessions per week.',
    youtubeUrl: 'https://www.youtube.com/watch?v=-WpVqYwYd44',
  ),

  // Nutrition Articles
  HealthArticle(
    title: 'A Balanced Diet: Understanding Food Groups And Healthy Eating ',
    category: 'Nutrition',
    description:
        'A balanced diet includes proteins, carbohydrates, fats, vitamins, and minerals. Eat a variety of colorful foods.',
    youtubeUrl: 'https://www.youtube.com/watch?v=81G22t2UHxA',
  ),
  
  HealthArticle(
    title: 'Healthy Snacking Habits',
    category: 'Nutrition',
    description:
        'Choose nutrient-dense snacks like nuts, fruits, and yogurt. Avoid processed foods high in sugar.',
    youtubeUrl: 'https://www.youtube.com/watch?v=Q4yUlJV31Rk',
  ),

  // Hydration Articles
  HealthArticle(
    title: 'Importance of Hydration',
    category: 'Hydration',
    description:
        'Drink at least 8 glasses of water daily. Proper hydration improves performance and cognitive function.',
    youtubeUrl: 'https://www.youtube.com/watch?v=-slnr4TGA4Y',
  ),
  HealthArticle(
    title: 'How to Properly Hydrate & How Much Water to Drink Each Day',
    category: 'Hydration',
    description:
        'hydration strategies, how factors like age, body weight, and activity level affect hydration needs, and actionable guidelines for daily water consumption whether your at rest or exercising.',
    youtubeUrl: 'https://www.youtube.com/watch?v=lwOPaNMTGh8',
  ),
  HealthArticle(
    title: 'Water and Exercise Recovery',
    category: 'Hydration',
    description:
        'Increase water intake during and after exercise. Electrolytes help maintain proper hydration balance.',
    youtubeUrl: 'https://www.youtube.com/watch?v=5--yogtN6oM',
  ),
  HealthArticle(
    title: 'Signs of Dehydration',
    category: 'Hydration',
    description:
        'Watch for dark urine, fatigue, and headaches. These are signs you need to drink more water.',
    youtubeUrl: 'https://www.youtube.com/watch?v=KahsIEbFROI',
  ),

  // Sleep Articles
  HealthArticle(
    title: 'Sleep Hygiene Tips',
    category: 'Sleep',
    description:
        'Maintain a consistent sleep schedule. Create a dark, cool, quiet bedroom for better sleep quality.',
    youtubeUrl: 'https://www.youtube.com/watch?v=ACmUi-6xkTM',
  ),
  HealthArticle(
    title: 'Why Sleep Matters',
    category: 'Sleep',
    description:
        'Quality sleep improves memory, mood, and immune function. Aim for 7-9 hours nightly.',
    youtubeUrl: 'https://www.youtube.com/watch?v=LmwgGkJ64CM',
  ),
  HealthArticle(
    title: 'Overcoming Sleep Issues',
    category: 'Sleep',
    description:
        'Limit screen time before bed. Avoid caffeine and establish a relaxing bedtime routine.',
    youtubeUrl: 'https://www.youtube.com/watch?v=YV1S01Fbsr4',
  ),

  // Weight Management Articles
  HealthArticle(
    title: 'Healthy Weight Management',
    category: 'Weight',
    description:
        'Focus on sustainable lifestyle changes, not quick fixes. Combine exercise with balanced nutrition.',
    youtubeUrl: 'https://www.youtube.com/watch?v=3h1nHxgsNyc',
  ),
  HealthArticle(
    title: 'Understanding BMI',
    category: 'Weight',
    description:
        'BMI is a screening tool for weight categories. Combine with other health metrics for complete picture.',
    youtubeUrl: 'https://www.youtube.com/watch?v=z_3S2_41_FE&t=167s',
  ),
  HealthArticle(
    title: 'Long-term Weight Loss',
    category: 'Weight',
    description:
        'Lose 1-2 pounds per week safely. Track progress with measurements and how your clothes fit.',
    youtubeUrl: 'https://www.youtube.com/watch?v=H1UTv7GG4Dw',
  ),
];