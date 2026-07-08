from PIL import Image
import os

def process_image():
    input_path = "/Users/bassoued/.gemini/antigravity-ide/brain/227c19d6-62ca-4d2e-a87d-a5dde4cd15d9/media__1783502793986.png"
    output_path = "public/signature-stamp.png"
    
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found")
        return
        
    img = Image.open(input_path)
    rgba = img.convert("RGBA")
    datas = rgba.getdata()
    
    newData = []
    for item in datas:
        # If the pixel is close to white (R, G, B > 230), make it transparent
        if item[0] > 230 and item[1] > 230 and item[2] > 230:
            newData.append((255, 255, 255, 0)) # transparent
        else:
            newData.append(item)
            
    rgba.putdata(newData)
    rgba.save(output_path, "PNG")
    print(f"✅ Success: Processed uploaded stamp with transparency and saved to {output_path}")

if __name__ == "__main__":
    process_image()
