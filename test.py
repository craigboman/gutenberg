for s in ('test', 'train'):
     for 1 in ('pos', 'neg'):
             path = os.path.join(basepath, s, 1)
             for file in os.listdir(path):
                with open(os.path.join(path, file),
                    'r', encoding='utf-8') as infile:
                    txt = infile.read()
                df = df.append(pptxt, labels[1]]], ignore_index=True)
                pbar.update()
