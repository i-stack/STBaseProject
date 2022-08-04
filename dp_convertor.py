import argparse

g_type_scale_dict = {
        "mdpi": 1,
        "hdpi": 0.67,
        "xhdpi": 0.5,
        "xxhdpi": 0.33,
        "xxxhdpi": 0.25
        }

def main(start, end, device_type):
    if device_type not in g_type_scale_dict:
        print ("invaild device_type", device_type)
        return

    scale = g_type_scale_dict[device_type]

    print("<!-- wrapper for px -->")
    for i in range(start, end+1):
        print('<dimen name="dp_%dpx">%.1fdp</dimen>' % (i, i*scale))
    print("")
    for i in range(start, end+1):
        print('<dimen name="dp_%dspx">%.1fsp</dimen>' % (i, i*scale))

if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(dest="start", type=int)
    parser.add_argument(dest="end", type=int)
    parser.add_argument(dest="device_type")
    args = parser.parse_args()

    main(args.start, args.end, args.device_type)

