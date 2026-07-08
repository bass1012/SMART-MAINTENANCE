from PIL import Image
import os

def crop_footer():
    image_path = "public/page-1.png"
    output_path = "public/footer.png"
    
    if not os.path.exists(image_path):
        print(f"Error: {image_path} not found")
        return
        
    img = Image.open(image_path)
    
    # 150 DPI: Width 1240, Height 1754
    # The footer is at the very bottom. Let's crop from Y=1600 to 1754
    left = 0
    top = 1580
    right = 1240
    bottom = 1754
    
    cropped = img.crop((left, top, right, bottom))
    cropped.save(output_path, "PNG")
    print(f"✅ Success: Cropped footer saved to {output_path}")

if __name__ == "__main__":
    crop_footer()
