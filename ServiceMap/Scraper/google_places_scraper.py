"""
ServiceMap Data Scraper - Google Places API Integration
Scrapes real businesses from Michigan for all service categories
"""

import os
import csv
import json
import time
from typing import List, Dict, Any
from googleplaces import GooglePlaces, types, geocode
import requests
from dotenv import load_dotenv

load_dotenv()

# Service categories to scrape
SERVICE_CATEGORIES = {
    'cleaning': ['house_cleaning', 'commercial_cleaning', 'window_cleaning'],
    'lawn_care': ['landscaping', 'lawn_mowing', 'tree_service', 'gardening'],
    'auto_detail': ['car_wash', 'car_detailing', 'auto_repair'],
    'handyman': ['handyman', 'carpenter', 'electrician', 'plumber'],
    'painting': ['painters', 'wallpapering'],
    'moving': ['movers', 'packing_services'],
    'pest_control': ['pest_control'],
    'hvac': ['heating_contractor', 'air_conditioning_contractor'],
    'roofing': ['roofer'],
    'flooring': ['flooring_contractor', 'carpet_cleaning'],
    'appliance_repair': ['appliance_repair'],
    'locksmith': ['locksmith'],
    'garage_door': ['garage_door_supplier'],
    'photography': ['photographer'],
    'tutoring': ['tutor'],
    'personal_training': ['personal_trainer'],
    'massage': ['massage_therapist'],
    'hair_salon': ['hair_salon', 'barber'],
    'nail_salon': ['nail_salon'],
    'spa': ['spa', 'day_spa'],
    'catering': ['caterer'],
    'bakery': ['bakery'],
    'pet_grooming': ['pet_groomer', 'pet_sitter', 'dog_walker'],
    'childcare': ['day_care_center', 'babysitter'],
    'elder_care': ['home_health_care_service'],
    'computer_repair': ['computer_repair_service'],
    'web_design': ['web_designer'],
    'graphic_design': ['graphic_designer'],
    'writing': ['copywriter', 'technical_writer'],
    'translation': ['translator'],
    'accounting': ['accountant', 'bookkeeping_service'],
    'legal': ['lawyer'],
    'real_estate': ['real_estate_agency'],
    'insurance': ['insurance_agency'],
    'financial_planning': ['financial_planner'],
}

# Michigan cities to target
MICHIGAN_CITIES = [
    {'city': 'Detroit', 'state': 'MI', 'lat': 42.3314, 'lng': -83.0458},
    {'city': 'Grand Rapids', 'state': 'MI', 'lat': 42.9634, 'lng': -85.6681},
    {'city': 'Warren', 'state': 'MI', 'lat': 42.5145, 'lng': -83.0147},
    {'city': 'Sterling Heights', 'state': 'MI', 'lat': 42.5803, 'lng': -83.0302},
    {'city': 'Ann Arbor', 'state': 'MI', 'lat': 42.2808, 'lng': -83.7430},
    {'city': 'Lansing', 'state': 'MI', 'lat': 42.7325, 'lng': -84.5555},
    {'city': 'Flint', 'state': 'MI', 'lat': 43.0125, 'lng': -83.6875},
    {'city': 'Dearborn', 'state': 'MI', 'lat': 42.3223, 'lng': -83.1763},
    {'city': 'Livonia', 'state': 'MI', 'lat': 42.3684, 'lng': -83.3527},
    {'city': 'Troy', 'state': 'MI', 'lat': 42.6064, 'lng': -83.1498},
    {'city': 'Westland', 'state': 'MI', 'lat': 42.3242, 'lng': -83.4002},
    {'city': 'Farmington Hills', 'state': 'MI', 'lat': 42.4989, 'lng': -83.3677},
    {'city': 'Kalamazoo', 'state': 'MI', 'lat': 42.2917, 'lng': -85.5872},
    {'city': 'Wyoming', 'state': 'MI', 'lat': 42.9134, 'lng': -85.7053},
    {'city': 'Southfield', 'state': 'MI', 'lat': 42.4734, 'lng': -83.2219},
    {'city': 'Rochester Hills', 'state': 'MI', 'lat': 42.6584, 'lng': -83.1499},
    {'city': 'Taylor', 'state': 'MI', 'lat': 42.2409, 'lng': -83.2697},
    {'city': 'Pontiac', 'state': 'MI', 'lat': 42.6389, 'lng': -83.2910},
    {'city': 'St. Clair Shores', 'state': 'MI', 'lat': 42.4974, 'lng': -82.8963},
    {'city': 'Royal Oak', 'state': 'MI', 'lat': 42.4895, 'lng': -83.1446},
]


class GooglePlacesScraper:
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.google_places = GooglePlaces(api_key)
        self.base_url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        
    def search_places(
        self, 
        keyword: str, 
        location: Dict[str, Any], 
        radius: int = 5000
    ) -> List[Dict[str, Any]]:
        """Search for places near a location"""
        places = []
        
        try:
            response = requests.get(
                self.base_url,
                params={
                    'location': f"{location['lat']},{location['lng']}",
                    'radius': radius,
                    'keyword': keyword,
                    'key': self.api_key,
                }
            )
            
            data = response.json()
            
            if data.get('status') == 'OK':
                places.extend(data.get('results', []))
                
                # Handle pagination
                while 'next_page_token' in data:
                    time.sleep(2)  # Required delay between requests
                    response = requests.get(
                        f"{self.base_url}?pagetoken={data['next_page_token']}&key={self.api_key}"
                    )
                    data = response.json()
                    if data.get('status') == 'OK':
                        places.extend(data.get('results', []))
                    else:
                        break
                        
            elif data.get('status') == 'ZERO_RESULTS':
                print(f"No results found for {keyword} in {location['city']}")
            else:
                print(f"Error searching {keyword}: {data.get('status')}")
                
        except Exception as e:
            print(f"Error searching {keyword}: {str(e)}")
            
        return places
    
    def enrich_place_details(self, place_id: str) -> Dict[str, Any]:
        """Get detailed information about a place"""
        try:
            response = requests.get(
                "https://maps.googleapis.com/maps/api/place/details/json",
                params={
                    'place_id': place_id,
                    'fields': 'name,formatted_address,formatted_phone_number,website,rating,user_ratings_total,photos,opening_hours,reviews,price_level,business_status',
                    'key': self.api_key,
                }
            )
            
            data = response.json()
            
            if data.get('status') == 'OK':
                return data.get('result', {})
            else:
                return {}
                
        except Exception as e:
            print(f"Error getting details for {place_id}: {str(e)}")
            return {}
    
    def scrape_category(
        self, 
        category: str, 
        subcategories: List[str],
        output_file: str
    ):
        """Scrape all businesses in a category across Michigan"""
        all_businesses = []
        
        for city in MICHIGAN_CITIES:
            print(f"\n🏙️  Searching {category} in {city['city']}, MI...")
            
            for subcategory in subcategories:
                print(f"  → {subcategory}")
                
                places = self.search_places(
                    keyword=subcategory.replace('_', ' '),
                    location=city,
                    radius=10000  # 10km radius
                )
                
                for place in places:
                    # Get detailed information
                    details = self.enrich_place_details(place.get('place_id', ''))
                    
                    if details:
                        business = {
                            'category': category,
                            'subcategory': subcategory,
                            'name': details.get('name', place.get('name', 'Unknown')),
                            'address': details.get('formatted_address', place.get('vicinity', '')),
                            'phone': details.get('formatted_phone_number', ''),
                            'website': details.get('website', ''),
                            'rating': details.get('rating', 0),
                            'review_count': details.get('user_ratings_total', 0),
                            'latitude': place.get('geometry', {}).get('location', {}).get('lat', 0),
                            'longitude': place.get('geometry', {}).get('location', {}).get('lng', 0),
                            'place_id': place.get('place_id', ''),
                            'photos': self.extract_photos(details.get('photos', [])),
                            'hours': details.get('opening_hours', {}).get('weekday_text', []),
                            'price_level': details.get('price_level', 0),
                            'business_status': details.get('business_status', ''),
                            'reviews': details.get('reviews', [])[:5],  # Top 5 reviews
                            'city': city['city'],
                            'state': city['state'],
                            'is_ghost': True,  # Mark as ghost provider
                            'request_count': 0,
                        }
                        
                        all_businesses.append(business)
                        print(f"    ✓ Found: {business['name']}")
                
                # Rate limiting
                time.sleep(1)
        
        # Save to CSV
        self.save_to_csv(all_businesses, output_file)
        print(f"\n✅ Saved {len(all_businesses)} businesses to {output_file}")
        
        return all_businesses
    
    def extract_photos(self, photos: List[Dict]) -> List[str]:
        """Extract photo URLs"""
        photo_urls = []
        
        for photo in photos[:5]:  # Limit to 5 photos
            photo_ref = photo.get('photo_reference', '')
            if photo_ref:
                url = f"https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference={photo_ref}&key={self.api_key}"
                photo_urls.append(url)
        
        return photo_urls
    
    def save_to_csv(self, businesses: List[Dict], filename: str):
        """Save businesses to CSV file"""
        if not businesses:
            return
            
        fieldnames = [
            'category', 'subcategory', 'name', 'address', 'phone', 'website',
            'rating', 'review_count', 'latitude', 'longitude', 'place_id',
            'photos', 'hours', 'price_level', 'business_status', 'reviews',
            'city', 'state', 'is_ghost', 'request_count'
        ]
        
        with open(filename, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            
            for business in businesses:
                # Convert complex fields to JSON strings
                row = business.copy()
                row['photos'] = json.dumps(row['photos'])
                row['hours'] = json.dumps(row['hours'])
                row['reviews'] = json.dumps(row['reviews'])
                writer.writerow(row)
    
    def scrape_all_categories(self, output_dir: str = './data'):
        """Scrape all service categories"""
        os.makedirs(output_dir, exist_ok=True)
        
        all_businesses = []
        
        for category, subcategories in SERVICE_CATEGORIES.items():
            print(f"\n{'='*60}")
            print(f"📊 Scraping Category: {category.upper()}")
            print(f"{'='*60}")
            
            output_file = os.path.join(output_dir, f'{category}_businesses.csv')
            businesses = self.scrape_category(category, subcategories, output_file)
            all_businesses.extend(businesses)
            
            # Rate limiting between categories
            time.sleep(2)
        
        # Save combined dataset
        combined_file = os.path.join(output_dir, 'all_michigan_businesses.csv')
        self.save_to_csv(all_businesses, combined_file)
        print(f"\n🎉 Total businesses scraped: {len(all_businesses)}")
        print(f"📁 Combined data saved to: {combined_file}")


def main():
    """Main entry point"""
    api_key = os.getenv('GOOGLE_PLACES_API_KEY')
    
    if not api_key:
        print("❌ Error: GOOGLE_PLACES_API_KEY not found in environment variables")
        print("Please set it in your .env file or export it:")
        print("  export GOOGLE_PLACES_API_KEY=your_api_key_here")
        return
    
    print("🚀 Starting ServiceMap Data Scraper")
    print(f"📍 Target: Michigan, USA")
    print(f"📋 Categories: {len(SERVICE_CATEGORIES)}")
    print(f"🏙️  Cities: {len(MICHIGAN_CITIES)}")
    print("\n⏳ This may take several minutes...\n")
    
    scraper = GooglePlacesScraper(api_key)
    scraper.scrape_all_categories()
    
    print("\n✅ Scraping complete!")
    print("\nNext steps:")
    print("1. Review the CSV files in ./data/")
    print("2. Run the migration script to import into database:")
    print("   python migrate_to_db.py")


if __name__ == '__main__':
    main()
