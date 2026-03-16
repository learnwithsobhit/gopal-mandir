-- Gopal Mandir — Seed Data

-- Aarti Schedule
INSERT INTO aarti_schedule (name, time, description, is_special) VALUES
('Mangla Aarti', '05:00 AM', 'Morning awakening aarti for Shri Gopal Ji', FALSE),
('Shringar Aarti', '07:30 AM', 'Decoration and adornment aarti', FALSE),
('Rajbhog Aarti', '11:30 AM', 'Mid-day offering aarti', FALSE),
('Utthapan Aarti', '03:30 PM', 'Afternoon awakening aarti', FALSE),
('Sandhya Aarti', '06:30 PM', 'Evening aarti with deep darshan', TRUE),
('Shayan Aarti', '08:30 PM', 'Night rest aarti for Shri Gopal Ji', FALSE);

-- Events
INSERT INTO events (title, date, description, image_url, is_featured) VALUES
('Holi Mahotsav', '2026-03-20', 'Grand Holi celebration with natural colours, bhajan sandhya, and prasad distribution.', NULL, TRUE),
('Ram Navami', '2026-04-04', 'Shri Ram Janmotsav with special puja, kirtan, and community bhandara.', NULL, TRUE),
('Janmashtami Mahotsav', '2026-08-25', 'Grand celebration of Shri Gopal Janmashtami with midnight darshan, dahi handi, and bhajan sandhya.', NULL, TRUE),
('Annakut Mahotsav', '2026-10-22', 'Govardhan Puja with 108 bhog offerings to Shri Gopal Ji.', NULL, FALSE),
('Weekly Satsang', 'Every Sunday', 'Bhagavad Gita discourse and kirtan every Sunday evening at 6 PM.', NULL, FALSE);

-- Gallery
INSERT INTO gallery (title, image_url, category) VALUES
('Shri Gopal Ji Shringar', 'https://picsum.photos/seed/gopal1/400/300', 'Darshan'),
('Janmashtami 2025', 'https://picsum.photos/seed/gopal2/400/300', 'Festival'),
('Temple Architecture', 'https://picsum.photos/seed/gopal3/400/300', 'Temple'),
('Annakut Bhog', 'https://picsum.photos/seed/gopal4/400/300', 'Festival'),
('Evening Aarti', 'https://picsum.photos/seed/gopal5/400/300', 'Darshan'),
('Holi Celebration', 'https://picsum.photos/seed/gopal6/400/300', 'Festival');

-- Prasad Items
INSERT INTO prasad_items (name, description, price, image_url, available) VALUES
('Peda Prasad', 'Traditional Mathura peda blessed by Shri Gopal Ji', 251.0, NULL, TRUE),
('Panchamrit Prasad', 'Sacred panchamrit from daily abhishek', 151.0, NULL, TRUE),
('Laddu Prasad', 'Besan laddu offered to Thakur Ji', 351.0, NULL, TRUE),
('Makhan Mishri', 'Butter and sugar crystals — Gopal Ji''s favourite', 201.0, NULL, TRUE);

-- Seva Items
INSERT INTO seva_items (name, description, price, category, available) VALUES
('Abhishek Seva', 'Sacred bathing of Shri Gopal Ji with milk, curd, honey, and gangajal', 1100.0, 'Daily Seva', TRUE),
('Shringar Seva', 'Sponsor the daily decoration and adornment of Thakur Ji', 2100.0, 'Daily Seva', TRUE),
('Annadan Seva', 'Sponsor bhandara meals for devotees', 5100.0, 'Special Seva', TRUE),
('Phool Bangla Seva', 'Flower decoration of the entire mandir sanctum', 11000.0, 'Special Seva', TRUE),
('Deep Daan', 'Light a ghee lamp in the sanctum on your behalf', 501.0, 'Daily Seva', TRUE);

-- Announcements
INSERT INTO announcements (title, message, date, is_urgent) VALUES
('Holi Mahotsav Schedule Released', 'The complete schedule for Holi Mahotsav 2026 is now available. Celebrations begin March 19th with Holika Dahan and continue through March 20th.', '2026-03-10', TRUE),
('New Prasad Booking System', 'You can now book prasad online and get it delivered to your home. Available for local delivery within city limits.', '2026-03-05', FALSE),
('Volunteer Registration Open', 'We are looking for volunteers for upcoming festivals. Register through the app or visit the mandir office.', '2026-03-01', FALSE);

-- Daily Quotes
INSERT INTO daily_quotes (shlok, translation, source) VALUES
('कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।
मा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि॥', 'You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself to be the cause of the results of your activities, nor be attached to inaction.', 'Bhagavad Gita 2.47'),
('यदा यदा हि धर्मस्य ग्लानिर्भवति भारत।
अभ्युत्थानमधर्मस्य तदात्मानं सृजाम्यहम्॥', 'Whenever there is a decline in righteousness and an increase in unrighteousness, O Arjuna, at that time I manifest myself on earth.', 'Bhagavad Gita 4.7'),
('सर्वधर्मान्परित्यज्य मामेकं शरणं व्रज।
अहं त्वां सर्वपापेभ्यो मोक्षयिष्यामि मा शुचः॥', 'Abandon all varieties of dharma and simply surrender unto Me alone. I shall liberate you from all sinful reactions; do not fear.', 'Bhagavad Gita 18.66');

-- Temple Info
INSERT INTO temple_info (name, address, city, phone, email, website, opening_time, closing_time, latitude, longitude) VALUES
('Shri Gopal Mandir', 'Gopal Mandir Road, Near Main Chowk', 'Vrindavan, Uttar Pradesh', '+91 98765 43210', 'info@shrigopalmandir.org', 'https://shrigopalmandir.org', '04:30 AM', '09:00 PM', 27.5839, 77.6964);
