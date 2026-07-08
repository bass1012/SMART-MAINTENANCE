from PIL import Image
import os

def crop_and_make_transparent():
    image_path = "public/page-1.png"
    output_path = "public/signature-stamp.png"
    
    if not os.path.exists(image_path):
        print(f"Error: {image_path} not found")
        return
        
    img = Image.open(image_path)
    
    # Coordinates of signature/stamp at 150 DPI:
    # Width is 1240, Height is 1754
    # The stamp is on the left near the bottom:
    # X: ~80 to ~650
    # Y: ~1180 to ~1550
    left = 80
    top = 1180
    right = 650
    bottom = 1540
    
    cropped = img.crop((left, top, right, bottom))
    
    # Make background transparent (white/light gray -> transparent)
    rgba = cropped.convert("RGBA")
    datas = rgba.getdata()
    
    newData = []
    for item in datas:
        # If the pixel is close to white, make it transparent
        if item[0] > 230 and item[1] > 230 and item[2] > 230:
            newData.append((255, 255, 255, 0)) # transparent
        else:
            newData.append(item)
            
    rgba.putdata(newData)
    rgba.save(output_path, "PNG")
    print(f"✅ Success: Cropped image saved with transparency to {output_path}")

if __name__ == "__main__":
    crop_and_make_transparent()
