use crate::models::*;

pub fn get_aarti_schedule() -> Vec<AartiSchedule> {
    vec![
        AartiSchedule {
            id: 1,
            name: "Mangla Aarti".to_string(),
            time: "05:00 AM".to_string(),
            description: "Morning awakening aarti for Shri Gopal Ji".to_string(),
            is_special: false,
        },
        AartiSchedule {
            id: 2,
            name: "Shringar Aarti".to_string(),
            time: "07:30 AM".to_string(),
            description: "Decoration and adornment aarti".to_string(),
            is_special: false,
        },
        AartiSchedule {
            id: 3,
            name: "Rajbhog Aarti".to_string(),
            time: "11:30 AM".to_string(),
            description: "Mid-day offering aarti".to_string(),
            is_special: false,
        },
        AartiSchedule {
            id: 4,
            name: "Utthapan Aarti".to_string(),
            time: "03:30 PM".to_string(),
            description: "Afternoon awakening aarti".to_string(),
            is_special: false,
        },
        AartiSchedule {
            id: 5,
            name: "Sandhya Aarti".to_string(),
            time: "06:30 PM".to_string(),
            description: "Evening aarti with deep darshan".to_string(),
            is_special: true,
        },
        AartiSchedule {
            id: 6,
            name: "Shayan Aarti".to_string(),
            time: "08:30 PM".to_string(),
            description: "Night rest aarti for Shri Gopal Ji".to_string(),
            is_special: false,
        },
    ]
}

pub fn get_events() -> Vec<Event> {
    vec![
        Event {
            id: 1,
            title: "Holi Mahotsav".to_string(),
            date: "2026-03-20".to_string(),
            description: "Grand Holi celebration with natural colours, bhajan sandhya, and prasad distribution.".to_string(),
            image_url: None,
            is_featured: true,
        },
        Event {
            id: 2,
            title: "Ram Navami".to_string(),
            date: "2026-04-04".to_string(),
            description: "Shri Ram Janmotsav with special puja, kirtan, and community bhandara.".to_string(),
            image_url: None,
            is_featured: true,
        },
        Event {
            id: 3,
            title: "Janmashtami Mahotsav".to_string(),
            date: "2026-08-25".to_string(),
            description: "Grand celebration of Shri Gopal Janmashtami with midnight darshan, dahi handi, and bhajan sandhya.".to_string(),
            image_url: None,
            is_featured: true,
        },
        Event {
            id: 4,
            title: "Annakut Mahotsav".to_string(),
            date: "2026-10-22".to_string(),
            description: "Govardhan Puja with 108 bhog offerings to Shri Gopal Ji.".to_string(),
            image_url: None,
            is_featured: false,
        },
        Event {
            id: 5,
            title: "Weekly Satsang".to_string(),
            date: "Every Sunday".to_string(),
            description: "Bhagavad Gita discourse and kirtan every Sunday evening at 6 PM.".to_string(),
            image_url: None,
            is_featured: false,
        },
    ]
}

pub fn get_gallery() -> Vec<GalleryItem> {
    vec![
        GalleryItem {
            id: 1,
            title: "Shri Gopal Ji Shringar".to_string(),
            image_url: "https://picsum.photos/seed/gopal1/400/300".to_string(),
            category: "Darshan".to_string(),
        },
        GalleryItem {
            id: 2,
            title: "Janmashtami 2025".to_string(),
            image_url: "https://picsum.photos/seed/gopal2/400/300".to_string(),
            category: "Festival".to_string(),
        },
        GalleryItem {
            id: 3,
            title: "Temple Architecture".to_string(),
            image_url: "https://picsum.photos/seed/gopal3/400/300".to_string(),
            category: "Temple".to_string(),
        },
        GalleryItem {
            id: 4,
            title: "Annakut Bhog".to_string(),
            image_url: "https://picsum.photos/seed/gopal4/400/300".to_string(),
            category: "Festival".to_string(),
        },
        GalleryItem {
            id: 5,
            title: "Evening Aarti".to_string(),
            image_url: "https://picsum.photos/seed/gopal5/400/300".to_string(),
            category: "Darshan".to_string(),
        },
        GalleryItem {
            id: 6,
            title: "Holi Celebration".to_string(),
            image_url: "https://picsum.photos/seed/gopal6/400/300".to_string(),
            category: "Festival".to_string(),
        },
    ]
}

pub fn get_prasad_items() -> Vec<PrasadItem> {
    vec![
        PrasadItem {
            id: 1,
            name: "Peda Prasad".to_string(),
            description: "Traditional Mathura peda blessed by Shri Gopal Ji".to_string(),
            price: 251.0,
            image_url: None,
            available: true,
        },
        PrasadItem {
            id: 2,
            name: "Panchamrit Prasad".to_string(),
            description: "Sacred panchamrit from daily abhishek".to_string(),
            price: 151.0,
            image_url: None,
            available: true,
        },
        PrasadItem {
            id: 3,
            name: "Laddu Prasad".to_string(),
            description: "Besan laddu offered to Thakur Ji".to_string(),
            price: 351.0,
            image_url: None,
            available: true,
        },
        PrasadItem {
            id: 4,
            name: "Makhan Mishri".to_string(),
            description: "Butter and sugar crystals — Gopal Ji's favourite".to_string(),
            price: 201.0,
            image_url: None,
            available: true,
        },
    ]
}

pub fn get_seva_items() -> Vec<SevaItem> {
    vec![
        SevaItem {
            id: 1,
            name: "Abhishek Seva".to_string(),
            description: "Sacred bathing of Shri Gopal Ji with milk, curd, honey, and gangajal".to_string(),
            price: 1100.0,
            category: "Daily Seva".to_string(),
            available: true,
        },
        SevaItem {
            id: 2,
            name: "Shringar Seva".to_string(),
            description: "Sponsor the daily decoration and adornment of Thakur Ji".to_string(),
            price: 2100.0,
            category: "Daily Seva".to_string(),
            available: true,
        },
        SevaItem {
            id: 3,
            name: "Annadan Seva".to_string(),
            description: "Sponsor bhandara meals for devotees".to_string(),
            price: 5100.0,
            category: "Special Seva".to_string(),
            available: true,
        },
        SevaItem {
            id: 4,
            name: "Phool Bangla Seva".to_string(),
            description: "Flower decoration of the entire mandir sanctum".to_string(),
            price: 11000.0,
            category: "Special Seva".to_string(),
            available: true,
        },
        SevaItem {
            id: 5,
            name: "Deep Daan".to_string(),
            description: "Light a ghee lamp in the sanctum on your behalf".to_string(),
            price: 501.0,
            category: "Daily Seva".to_string(),
            available: true,
        },
    ]
}

pub fn get_announcements() -> Vec<Announcement> {
    vec![
        Announcement {
            id: 1,
            title: "Holi Mahotsav Schedule Released".to_string(),
            message: "The complete schedule for Holi Mahotsav 2026 is now available. Celebrations begin March 19th with Holika Dahan and continue through March 20th.".to_string(),
            date: "2026-03-10".to_string(),
            is_urgent: true,
        },
        Announcement {
            id: 2,
            title: "New Prasad Booking System".to_string(),
            message: "You can now book prasad online and get it delivered to your home. Available for local delivery within city limits.".to_string(),
            date: "2026-03-05".to_string(),
            is_urgent: false,
        },
        Announcement {
            id: 3,
            title: "Volunteer Registration Open".to_string(),
            message: "We are looking for volunteers for upcoming festivals. Register through the app or visit the mandir office.".to_string(),
            date: "2026-03-01".to_string(),
            is_urgent: false,
        },
    ]
}

pub fn get_daily_quote() -> DailyQuote {
    DailyQuote {
        shlok: "कर्मण्येवाधिकारस्ते मा फलेषु कदाचन।\nमा कर्मफलहेतुर्भूर्मा ते सङ्गोऽस्त्वकर्मणि॥".to_string(),
        translation: "You have a right to perform your prescribed duties, but you are not entitled to the fruits of your actions. Never consider yourself to be the cause of the results of your activities, nor be attached to inaction.".to_string(),
        source: "Bhagavad Gita 2.47".to_string(),
    }
}

pub fn get_temple_info() -> TempleInfo {
    TempleInfo {
        name: "Shri Gopal Mandir".to_string(),
        address: "Gopal Mandir Road, Near Main Chowk".to_string(),
        city: "Vrindavan, Uttar Pradesh".to_string(),
        phone: "+91 98765 43210".to_string(),
        email: "info@shrigopalmandir.org".to_string(),
        website: "https://shrigopalmandir.org".to_string(),
        opening_time: "04:30 AM".to_string(),
        closing_time: "09:00 PM".to_string(),
        latitude: 27.5839,
        longitude: 77.6964,
    }
}
