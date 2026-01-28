import { useState, useEffect, useRef } from 'react';
import { Search, MapPin } from 'lucide-react';

export default function GoogleMapComponent({ latitude, longitude, location, onLocationSelect }) {
  const mapRef = useRef(null);
  const mapInstanceRef = useRef(null);
  const searchBoxRef = useRef(null);
  const markerRef = useRef(null);
  const [isMapLoaded, setIsMapLoaded] = useState(false);
  const [searchInput, setSearchInput] = useState(location || '');

  // Load Google Maps script
  useEffect(() => {
    const script = document.createElement('script');
    script.src = `https://maps.googleapis.com/maps/api/js?key=${import.meta.env.VITE_GOOGLE_MAPS_API_KEY}&libraries=places`;
    script.async = true;
    script.defer = true;
    script.onload = () => {
      setIsMapLoaded(true);
    };
    script.onerror = () => {
      console.error('Failed to load Google Maps');
    };
    document.head.appendChild(script);

    return () => {
      document.head.removeChild(script);
    };
  }, []);

  // Initialize map
  useEffect(() => {
    if (!isMapLoaded || !mapRef.current) return;

    const initialLat = latitude ? parseFloat(latitude) : 19.0760; // Default: Mumbai
    const initialLng = longitude ? parseFloat(longitude) : 72.8777;

    const map = new window.google.maps.Map(mapRef.current, {
      zoom: 12,
      center: { lat: initialLat, lng: initialLng },
      mapTypeControl: true,
      fullscreenControl: true,
      streetViewControl: true,
    });

    mapInstanceRef.current = map;

    // Add marker
    const marker = new window.google.maps.Marker({
      position: { lat: initialLat, lng: initialLng },
      map: map,
      draggable: true,
    });

    markerRef.current = marker;

    // Handle marker drag
    marker.addListener('dragend', () => {
      const pos = marker.getPosition();
      const newLat = pos.lat().toFixed(8);
      const newLng = pos.lng().toFixed(8);
      onLocationSelect(searchInput, newLat, newLng);
    });

    // Handle map click
    map.addListener('click', (event) => {
      const lat = event.latLng.lat().toFixed(8);
      const lng = event.latLng.lng().toFixed(8);
      marker.setPosition({ lat: parseFloat(lat), lng: parseFloat(lng) });
      
      // Get address from coordinates (reverse geocoding)
      reverseGeocode({ lat, lng }, marker);
      onLocationSelect(searchInput, lat, lng);
    });

    // Initialize search box
    if (searchBoxRef.current) {
      const searchBox = new window.google.maps.places.SearchBox(searchBoxRef.current);
      map.controls[window.google.maps.ControlPosition.TOP_LEFT].push(searchBoxRef.current);

      // Listen to places changed
      searchBox.addListener('places_changed', () => {
        const places = searchBox.getPlaces();
        if (places.length === 0) return;

        const place = places[0];
        if (!place.geometry || !place.geometry.location) return;

        const lat = place.geometry.location.lat().toFixed(8);
        const lng = place.geometry.location.lng().toFixed(8);
        const placeAddress = place.formatted_address;

        // Update marker
        marker.setPosition({ lat: parseFloat(lat), lng: parseFloat(lng) });
        
        // Pan map to location
        map.panTo(new window.google.maps.LatLng(parseFloat(lat), parseFloat(lng)));

        // Update search input
        setSearchInput(placeAddress);
        onLocationSelect(placeAddress, lat, lng);
      });
    }
  }, [isMapLoaded, latitude, longitude]);

  // Reverse geocoding function
  const reverseGeocode = (coords, marker) => {
    if (!window.google) return;

    const geocoder = new window.google.maps.Geocoder();
    const location = {
      lat: parseFloat(coords.lat),
      lng: parseFloat(coords.lng),
    };

    geocoder.geocode({ location }, (results, status) => {
      if (status === 'OK' && results[0]) {
        const address = results[0].formatted_address;
        setSearchInput(address);
      }
    });
  };

  const handleSearchChange = (e) => {
    setSearchInput(e.target.value);
  };

  if (!isMapLoaded) {
    return (
      <div className="w-full h-96 bg-lodha-sand rounded-lg flex items-center justify-center border border-lodha-gold/30">
        <p className="text-lodha-black/50 font-jost">Loading Google Maps...</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {/* Search Box */}
      <div className="relative">
        <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <Search className="w-4 h-4 text-lodha-gold/60" />
        </div>
        <input
          ref={searchBoxRef}
          type="text"
          value={searchInput}
          onChange={handleSearchChange}
          placeholder="Search for location or address..."
          className="w-full pl-10 pr-4 py-2 border border-lodha-grey rounded-lg focus:outline-none focus:ring-2 focus:ring-lodha-gold"
        />
      </div>

      {/* Map */}
      <div
        ref={mapRef}
        className="w-full h-96 rounded-lg shadow-md border border-lodha-grey"
      />

      {/* Info */}
      <div className="p-3 bg-lodha-sand rounded-lg border border-lodha-gold">
        <div className="flex gap-2 items-start">
          <MapPin className="w-4 h-4 text-lodha-gold mt-0.5 flex-shrink-0" />
          <div className="text-sm text-lodha-black font-jost">
            <p className="font-semibold mb-1">Tips:</p>
            <ul className="space-y-1 text-xs">
              <li>• Search for address in the search box</li>
              <li>• Click on map to place marker</li>
              <li>• Drag marker to adjust location</li>
              <li>• Coordinates auto-populate from map</li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
}
