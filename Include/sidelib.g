
dll sidelib function Test();
dll sidelib function ConvertFonts(ptr source, ptr fontchar256, ptr fontchar32);
dll sidelib function ConvertFont1024(ptr source, ptr fontchar1024, int nrRows);
dll sidelib function LoadImage(ptr fullPathToImage);
dll sidelib function LoadAndExpandImage(ptr fullPathToImage, int expandNr);
dll sidelib function FreeImage(ptr image);
dll sidelib function FlipRedAndGreenInImage(ptr image, int SizeX, int SizeY);
