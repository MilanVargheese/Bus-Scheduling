"""
Test the prediction API endpoint
"""
import requests
import json

def test_predict(csv_file="test_input.csv"):
    """Test the /predict endpoint"""
    
    url = "http://localhost:8000/predict"
    
    print("=" * 80)
    print(f"Testing prediction endpoint with: {csv_file}")
    print("=" * 80)
    
    try:
        # Open and send file
        with open(csv_file, 'rb') as f:
            files = {'file': (csv_file, f, 'text/csv')}
            response = requests.post(url, files=files)
        
        print(f"\nStatus Code: {response.status_code}")
        print(f"Response Headers: {dict(response.headers)}")
        
        if response.status_code == 200:
            result = response.json()
            print("\n✓ SUCCESS!")
            print(f"\nStatus: {result.get('status')}")
            
            if 'metadata' in result:
                print("\nMetadata:")
                for key, value in result['metadata'].items():
                    print(f"  {key}: {value}")
            
            if 'predictions' in result:
                print("\nPredictions:")
                for key, values in result['predictions'].items():
                    if values:
                        print(f"  {key}: {len(values)} values")
                        print(f"    First 5: {values[:5]}")
                        print(f"    Mean: {sum(values)/len(values):.2f}")
        else:
            print("\n✗ FAILED!")
            print(f"\nError Response:")
            print(json.dumps(response.json(), indent=2))
    
    except Exception as e:
        print(f"\n✗ ERROR: {e}")
        import traceback
        traceback.print_exc()


def test_health():
    """Test the health endpoints"""
    print("=" * 80)
    print("Testing health endpoints")
    print("=" * 80)
    
    # Main health
    response = requests.get("http://localhost:8000/health")
    print(f"\n/health: {response.status_code}")
    print(json.dumps(response.json(), indent=2))
    
    # Prediction health
    response = requests.get("http://localhost:8000/predict/health")
    print(f"\n/predict/health: {response.status_code}")
    print(json.dumps(response.json(), indent=2))


if __name__ == "__main__":
    # Test health first
    test_health()
    
    print("\n")
    
    # Test with different CSV files
    test_predict("test_input.csv")
    
    print("\n")
    
    # Test with minimal file
    test_predict("test_input_minimal.csv")
    
    print("\n")
    
    # Test with large file
    test_predict("test_input_large.csv")
