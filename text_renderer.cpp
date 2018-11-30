#include "text_renderer.h"

void setTextRendererProjection(TextRenderer* textRenderer, float left, float right, float bottom, float top){
    Matrix4 perspMat = createOrthogonalProjectionMatrix(left, right, bottom, top, -1, 1);
    TextUniforms* unis = (TextUniforms*)textRenderer->renderDevice->getPointerToBufferData(&textRenderer->uniformBuffer);
    unis->perspectiveMatrix = perspMat;
}

void loadCharacterAtlas(unsigned char* fileData, CharacterAtlas* fa){
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

TextObject* createTextObject(TextObjectManager* tomgr, const s8* text, f32 x, f32 y, f32 scale = 1, Vector4 color = Vector4(0, 0, 0, 1)){
    ASSERT(tomgr->totalTextObjects < TextObjectManager::MAX_TEXT_OBJECTS);

    s8 c;
    u32 totalChars = 0;
    u32 totalTextObjects = tomgr->totalTextObjects;
    TextObject* tobj = &tomgr->textObjects[totalTextObjects];
    do{
        c = text[totalChars];
        ASSERT(totalChars < TextObject::MAX_STRING_LENGTH);
        tobj->text[totalChars] = c;
        totalChars++;
    }
    while(c != '\0');

    tobj->textLength = totalChars;
    tobj->x = x;
    tobj->y = y;
    tobj->scale = scale;
    tobj->color = color;
    tobj->index = totalTextObjects;

    tomgr->totalTextObjects++;

    return tobj;
}

void prepareTextRenderer(TextRenderer* textRenderer){
    RenderDevice* device = textRenderer->renderDevice;
    device->bindShader(&textRenderer->shader);
    device->bindTexture2D(&textRenderer->characterAtlasTexture);
    device->bindVertexBuffer(&textRenderer->vertexBuffer);
    device->bindIndexBuffer(&textRenderer->indexBuffer);
    device->bindVertexUniformBuffer(&textRenderer->uniformBuffer);
    textRenderer->totalVertices = 0;
    textRenderer->totalIndices = 0;
}

void renderTextObjects(TextRenderer* textRenderer, TextObjectManager* txtObjMgr){
    RenderDevice* device = textRenderer->renderDevice;

    u32 totalTextObjects = txtObjMgr->totalTextObjects;
    CharacterAtlas* charAtls = &textRenderer->charAtlas;
    u32 vertCt = textRenderer->totalVertices * 8;
    u32 indCt = textRenderer->totalIndices * 6;
    for(u32 i = 0; i < totalTextObjects; i++){
        TextObject* txtObj = &txtObjMgr->textObjects[i];

        TextUniforms* unis = (TextUniforms*)device->getPointerToBufferData(&textRenderer->uniformBuffer);
        unis->colors[i] = txtObj->color;

        u32 totalChars = txtObj->textLength;
        f32 xMarker = txtObj->x;
        f32 yMarker = txtObj->y;
        for(u32 j = 0; j < totalChars; j++){
            s8 c = txtObj->text[j];
            u32 totalChars = charAtls->totalCharacters;
            u32 k;
            for(k = 0; k < totalChars; k++){
                if(c == charAtls->characterCodes[k]){
                    break;
                }
            }
            if(k == totalChars){
                continue;
            }

            f32 scale = txtObj->scale;
            if(c == ' '){
                xMarker += charAtls->xShifts[k] * scale;
                continue;
            }
            
            f32 width = charAtls->widths[k];
            f32 height = charAtls->heights[k];
            f32 xOff = charAtls->xOffsets[k];
            f32 yOff = charAtls->yOffsets[k];
            f32 bitmapWidth = charAtls->totalBitmapWidth;
            f32 bitmapHeight = charAtls->totalBitmapHeight;


            f32 left = xMarker;
            f32 right = xMarker + width * scale;
            f32 bottom = yMarker + charAtls->yShifts[k] * scale;
            f32 top = yMarker + height * scale;
            f32 tLeft = xOff / bitmapWidth;
            f32 tRight = (xOff + width) / bitmapWidth;
            f32 tBottom = yOff / bitmapHeight;
            f32 tTop = (yOff + height) / bitmapHeight;

            f32* vertPtr = (f32*)device->getPointerToBufferData(&textRenderer->vertexBuffer);
            u16* indPtr = (u16*)device->getPointerToBufferData(&textRenderer->indexBuffer);
            vertPtr[vertCt++] = left;  vertPtr[vertCt++] =  bottom;
            vertPtr[vertCt++] = tLeft; vertPtr[vertCt++] = tBottom;
            vertPtr[vertCt++] = i;
            vertPtr[vertCt++] = left;  vertPtr[vertCt++] =  top;
            vertPtr[vertCt++] = tLeft; vertPtr[vertCt++] = tTop;
            vertPtr[vertCt++] = i;
            vertPtr[vertCt++] = right;  vertPtr[vertCt++] =  top;
            vertPtr[vertCt++] = tRight; vertPtr[vertCt++] = tTop;
            vertPtr[vertCt++] = i;
            vertPtr[vertCt++] = right;  vertPtr[vertCt++] =  bottom;
            vertPtr[vertCt++] = tRight; vertPtr[vertCt++] = tBottom;
            vertPtr[vertCt++] = i;
            textRenderer->totalVertices += 4;
            
            indPtr[indCt++] = textRenderer->totalVertices - 4;
            indPtr[indCt++] = textRenderer->totalVertices - 3;
            indPtr[indCt++] = textRenderer->totalVertices - 2;
            indPtr[indCt++] = textRenderer->totalVertices - 2;
            indPtr[indCt++] = textRenderer->totalVertices - 1;
            indPtr[indCt++] = textRenderer->totalVertices - 4;
            textRenderer->totalIndices += 6;
            xMarker += charAtls->xShifts[k] * scale;
        }
    }
}

void finalizeTextRenderer(TextRenderer* textRenderer){
    textRenderer->renderDevice->drawIndices(0, textRenderer->totalIndices, RENDERER_INDEX_TYPE_U16, RENDER_DRAW_MODE_TRIANGLES);
}

void initializeTextRenderer(OSDevice* osDevice, RenderDevice* renderDevice, TextRenderer* textRenderer){
    textRenderer->osDevice = osDevice;
    textRenderer->renderDevice = renderDevice;
    textRenderer->totalVertices = 0;
    textRenderer->totalIndices = 0;
    u8* fontFileData;
    u64 len;
    const s8* faPth = osDevice->getPathFromExecutable("font atlas builder/courier_new.fontatlas");
    osDevice->readBinaryFile(faPth, &fontFileData, &len);
    delete[]faPth;
    loadCharacterAtlas(fontFileData, &textRenderer->charAtlas);

    renderDevice->createBuffer(&textRenderer->vertexBuffer, TextRenderer::MAX_VERTICES, 0);
    renderDevice->createBuffer(&textRenderer->indexBuffer, TextRenderer::MAX_INDICES, 1);
    renderDevice->createBuffer(&textRenderer->uniformBuffer, sizeof(TextUniforms), 2);
    renderDevice->createTexture2DWithData(&textRenderer->characterAtlasTexture, textRenderer->charAtlas.bitmap, textRenderer->charAtlas.totalBitmapWidth, textRenderer->charAtlas.totalBitmapHeight, textRenderer->charAtlas.totalBitmapWidth, RENDERER_PIXEL_SIZE_R8, 0, 0);

    RendererVertexFormat rvf[] = {
        RENDERER_VERTEX_FORMAT_F32x2, RENDERER_VERTEX_FORMAT_F32x2, RENDERER_VERTEX_FORMAT_F32
    };
    u32 elemSizes[] = {
        sizeof(float), sizeof(float), sizeof(float)
    };
    u32 bufOffs[] = {
        0, sizeof(float) * 2, sizeof(float) * 4
    };
    VertexBufferDescriptor vbd;
    vbd.totalAttributes = 3;
    vbd.rendererVertexFormats = rvf;
    vbd.attributeElementSizes = elemSizes;
    vbd.attributeBufferOffsets = bufOffs;

    s8* shaderText;
    u64 fileLength;
    const s8* shPth = osDevice->getPathFromExecutable("text_shader.metal");
    osDevice->readTextFile(shPth, &shaderText, &fileLength);
    delete[] shPth;

    renderDevice->createShaderFromString(&textRenderer->shader, (const char*)shaderText, "vertexShader", "fragmentShader", &textRenderer->vertexBuffer, &vbd);
    renderDevice->bindShader(&textRenderer->shader);
    renderDevice->bindVertexBuffer(&textRenderer->vertexBuffer);
    renderDevice->bindVertexUniformBuffer(&textRenderer->uniformBuffer);
    renderDevice->enableBlending(true);

    renderDevice->createTexture2DWithData(&textRenderer->characterAtlasTexture, textRenderer->charAtlas.bitmap, 
                                                   textRenderer->charAtlas.totalBitmapWidth, 
                                                   textRenderer->charAtlas.totalBitmapHeight, 
                                                   textRenderer->charAtlas.totalBitmapWidth, RENDERER_PIXEL_SIZE_R8, 0, 0);

}