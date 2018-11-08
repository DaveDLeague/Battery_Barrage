#include "text_renderer.h"

void loadFontAtlas(unsigned char* fileData, FontAtlas* fa){
    fa->totalCharacters = *(unsigned int*)fileData;
    fileData += sizeof(unsigned int);
    fa->totalBitmapWidth = *(unsigned int*)fileData;
    fileData += sizeof(unsigned int);
    fa->totalBitmapHeight = *(unsigned int*)fileData;
    fileData += sizeof(unsigned int);

    u32 totalBitmapSize = fa->totalBitmapWidth * fa->totalBitmapHeight;

    u32 totalChars = fa->totalCharacters;
    fa->bitmap = new u8[totalBitmapSize];
    fa->characterCodes = new u16[totalChars];
    fa->xOffsets = new u32[totalChars];
    fa->yOffsets = new u32[totalChars];
    fa->widths = new u32[totalChars];
    fa->heights = new u32[totalChars];
    fa->xShifts = new f32[totalChars];
    fa->yShifts = new f32[totalChars];

    for(u32 i = 0; i < totalBitmapSize; i++){
        fa->bitmap[i] = *(unsigned char*)fileData;
        fileData++;
    }

    u16* cCodes = (u16*)fileData;
    fileData += sizeof(u16) * totalChars;
    u32* xOffs = (u32*)fileData;
    fileData += sizeof(u32) * totalChars;
    u32* yOffs = (u32*)fileData;
    fileData += sizeof(u32) * totalChars;
    u32* wds = (u32*)fileData;
    fileData += sizeof(u32) * totalChars;
    u32* hts = (u32*)fileData;
    fileData += sizeof(u32) * totalChars;
    f32* xSft = (f32*)fileData;
    fileData += sizeof(f32) * totalChars;
    f32* ySft = (f32*)fileData;

    for(u32 i = 0; i < totalChars; i++){
        fa->characterCodes[i] = *(cCodes + i);
        fa->xOffsets[i] = *(xOffs + i);
        fa->yOffsets[i] = *(yOffs + i);
        fa->widths[i] = *(wds + i);
        fa->heights[i] = *(hts + i);
        fa->xShifts[i] = *(xSft + i);
        fa->yShifts[i] = *(ySft + i);
    }
}

TextObject* createTextObject(TextRenderer* textRenderer, const s8* text, float x, float y, float scale){
    TextObject* tObj = &textRenderer->textObjects[textRenderer->totalTextObjects];

    u32 len = 0;
    while(true){
        tObj->text[len] = text[len];
        if(text[len++] == '\0'){
            break;
        }
    }
    
    tObj->fontAtlas = &textRenderer->fontAtlas;
    
    tObj->textLength = len;
    tObj->scale = scale;
    tObj->x = x;
    tObj->y = y;
    
    textRenderer->totalTextObjects++;
   
    return tObj;
}

void setTextObjectText(TextObject* txtObj, const s8* text, ...){
    u32 len = 0;
    while(true){
        txtObj->text[len] = text[len];
        if(text[len++] == '\0'){
            break;
        }
    }
    txtObj->textLength = len;
}

void prepareTextBuffers(TextRenderer* textRenderer, f32* vertBuffer, u16* indBuffer){
    FontAtlas* fa = &textRenderer->fontAtlas;
    f32 totalWidth = (f32)fa->totalBitmapWidth;
    f32 totalHeight = (f32)fa->totalBitmapHeight;
    u32 vCtr = 0;     
    u32 iCtr = 0;
    u32 vertCount = 0;
    for(int i = 0; i < textRenderer->totalTextObjects; i++){
        TextObject* fo = &textRenderer->textObjects[i];

        const s8* text = fo->text;
        f32 xOff;
        f32 yOff;
        f32 width;
        f32 height;
        f32 xShift;
        f32 yShift;
        f32 scale = fo->scale;
    
        f32 xMarker = (f32)fo->x;
        f32 y = (f32)fo->y;
        s8 c = *text;
        while(c != '\0'){
            for(u32 j = 0; j < fa->totalCharacters; j++){
                if(fa->characterCodes[j] == c){
                    xOff = (f32)fa->xOffsets[j];
                    yOff = (f32)fa->yOffsets[j];
                    width = (f32)fa->widths[j];
                    height = (f32)fa->heights[j];
                    xShift = (f32)fa->xShifts[j];
                    yShift = (f32)fa->yShifts[j];
                    break;
                }
            }

            if(c != ' '){
                vertBuffer[vCtr++] = xMarker; vertBuffer[vCtr++] = y + (yShift * scale);
                vertBuffer[vCtr++] = xOff / totalWidth; vertBuffer[vCtr++] = yOff / totalHeight;

                vertBuffer[vCtr++] = xMarker; vertBuffer[vCtr++] = y + ((yShift + height) * scale);
                vertBuffer[vCtr++] = xOff / totalWidth; vertBuffer[vCtr++] = (yOff + height) / totalHeight;

                vertBuffer[vCtr++] = xMarker + (width * scale); vertBuffer[vCtr++] = y + ((yShift + height) * scale);
                vertBuffer[vCtr++] = (xOff + width) / totalWidth; vertBuffer[vCtr++] = (yOff + height) / totalHeight;

                vertBuffer[vCtr++] = xMarker + (width * scale); vertBuffer[vCtr++] = y + (yShift * scale);
                vertBuffer[vCtr++] = (xOff + width) / totalWidth; vertBuffer[vCtr++] = yOff / totalHeight;
                vertCount += 4;

                indBuffer[iCtr++] = vertCount - 4;
                indBuffer[iCtr++] = vertCount - 3;
                indBuffer[iCtr++] = vertCount - 2;
                indBuffer[iCtr++] = vertCount - 2;
                indBuffer[iCtr++] = vertCount - 1;
                indBuffer[iCtr++] = vertCount - 4;
            }

            xMarker += xShift * scale;
            text++;
            c = *text;
        }
    }
    textRenderer->totalVertices = vertCount;
    textRenderer->totalIndices = (vertCount / 4) * 6;
}