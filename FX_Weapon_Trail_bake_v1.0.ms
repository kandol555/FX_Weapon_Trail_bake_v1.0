/*
    FX_Weapon_Trail_bake v1.0
    Combined tool: Mesh Bake + Line Bake
    3ds Max 2018 ~ latest compatibility target

    User-facing UI: Korean
    Generated object/material names: English only

    Mesh output name: FX_Trail_mash_001
    Line output name: FX_Trail_line_001
*/

global FXTB_Floater

global FXTB_MeshAppDataID = 920431
global FXTB_LineAppDataID = 920432
global FXTB_MeshAppDataValue = "FX_Weapon_Trail_bake_mesh_v1_0"
global FXTB_LineAppDataValue = "FX_Weapon_Trail_bake_line_v1_0"

global FXTB_pickObjA = undefined
global FXTB_pickObjB = undefined

fn FXTB_Linear p1 p2 t =
(
    p1 * (1.0 - t) + p2 * t
)

fn FXTB_CatmullRomSafe t p1 p2 p3 p4 =
(
    local t2 = t * t
    local t3 = t2 * t
    0.5 * ((2.0*p2) + ((-p1 + p3) * t) + ((2.0*p1 - 5.0*p2 + 4.0*p3 - p4) * t2) + ((-p1 + 3.0*p2 - 3.0*p3 + p4) * t3))
)

fn FXTB_ClampIndex idx count =
(
    if idx < 1 then 1 else if idx > count then count else idx
)

fn FXTB_ForceSceneEval f =
(
    try(sliderTime = f)catch()
    try(redrawViews())catch()
    try(completeRedraw())catch()
)

/*
    Sample mode
    1 = Parent included position: local position multiplied by parent world TM
    2 = World position
    3 = Transform row4
    4 = Original pos
*/
fn FXTB_GetNodePos obj f sampleMode forceEval =
(
    if obj == undefined then return [0,0,0]
    if forceEval do FXTB_ForceSceneEval f

    local result = [0,0,0]
    at time f
    (
        case sampleMode of
        (
            1:
            (
                if obj.parent != undefined then
                (
                    local localP = in coordsys parent obj.pos
                    result = localP * obj.parent.transform
                )
                else
                (
                    result = in coordsys world obj.pos
                )
            )
            2:
            (
                result = in coordsys world obj.pos
            )
            3:
            (
                result = obj.transform.row4
            )
            4:
            (
                result = obj.pos
            )
            default:
            (
                if obj.parent != undefined then
                (
                    local localP = in coordsys parent obj.pos
                    result = localP * obj.parent.transform
                )
                else
                (
                    result = in coordsys world obj.pos
                )
            )
        )
    )
    result
)

fn FXTB_GetNextName prefix =
(
    local idx = 1
    local nm = ""
    while true do
    (
        nm = prefix + (formattedPrint idx format:"03d")
        if getNodeByName nm == undefined then exit
        idx += 1
    )
    nm
)

fn FXTB_MakeMeshMaterial =
(
    local mat = standardMaterial name:(uniqueName "FX_Trail_Mat_")
    try(mat.diffuse = color 70 180 255)catch()
    try(mat.opacity = 100)catch()
    try(mat.selfIllumAmount = 100)catch()
    try(mat.twoSided = true)catch()
    mat
)

fn FXTB_MakeLineMaterial =
(
    local mat = standardMaterial name:(uniqueName "FX_Trail_Line_Mat_")
    try(mat.diffuse = color 255 220 80)catch()
    try(mat.opacity = 100)catch()
    try(mat.selfIllumAmount = 100)catch()
    try(mat.twoSided = true)catch()
    mat
)

fn FXTB_CreateDebugPoints posArray namePrefix appId appValue =
(
    for i = 1 to posArray.count do
    (
        local p = point name:(uniqueName (namePrefix + "_Sample_")) size:3 cross:true box:false pos:posArray[i]
        try(setAppData p appId appValue)catch()
    )
)

fn FXTB_DeleteByAppData appId appValue =
(
    local delArr = #()
    for o in objects do
    (
        local v = undefined
        try(v = getAppData o appId)catch(v = undefined)
        if v == appValue do append delArr o
    )
    if delArr.count > 0 then delete delArr
    delArr.count
)

fn FXTB_DeleteAllCreated =
(
    local n1 = FXTB_DeleteByAppData FXTB_MeshAppDataID FXTB_MeshAppDataValue
    local n2 = FXTB_DeleteByAppData FXTB_LineAppDataID FXTB_LineAppDataValue
    n1 + n2
)

fn FXTB_ApplyRenderableSettings obj =
(
    if obj == undefined do return false
    try(obj.renderable = true)catch()
    try(obj.primaryVisibility = true)catch()
    try(obj.visibleToCamera = true)catch()
    try(obj.castShadows = false)catch()
    try(obj.receiveShadows = false)catch()
    true
)

fn FXTB_ApplyLineRenderableSettings obj renderableLine lineThickness =
(
    if obj == undefined do return false
    FXTB_ApplyRenderableSettings obj
    try(obj.render_renderable = renderableLine)catch()
    try(obj.render_displayRenderMesh = renderableLine)catch()
    try(obj.render_thickness = lineThickness)catch()
    try(obj.render_sides = 6)catch()
    try(obj.render_viewport_thickness = lineThickness)catch()
    true
)

fn FXTB_SetMeshUVs mnode tverts uvFaces =
(
    if mnode == undefined do return false
    try
    (
        setNumTVerts mnode.mesh tverts.count
        buildTVFaces mnode.mesh
        for i = 1 to tverts.count do setTVert mnode.mesh i tverts[i]
        for i = 1 to uvFaces.count do setTVFace mnode.mesh i uvFaces[i]
        true
    )
    catch
    (
        format "[FX_Weapon_Trail_bake v1.0] UV setup failed.\n"
        false
    )
)

fn FXTB_HideQuadDiagonals mnode quadCount =
(
    if mnode == undefined do return false
    try
    (
        for q = 1 to quadCount do
        (
            local fA = (q - 1) * 2 + 1
            local fB = fA + 1
            setEdgeVis mnode.mesh fA 3 false
            setEdgeVis mnode.mesh fB 1 false
        )
        true
    )
    catch
    (
        try
        (
            for q = 1 to quadCount do
            (
                local fA = (q - 1) * 2 + 1
                local fB = fA + 1
                setEdgeVis mnode fA 3 false
                setEdgeVis mnode fB 1 false
            )
            true
        )
        catch(false)
    )
)

fn FXTB_BuildTrailMeshNode meshName verts tverts triFaces makeQuad =
(
    local mnode = mesh vertices:verts faces:triFaces
    mnode.name = meshName

    FXTB_SetMeshUVs mnode tverts triFaces
    FXTB_HideQuadDiagonals mnode (triFaces.count / 2)
    try(update mnode)catch()

    if makeQuad do
    (
        try
        (
            convertToPoly mnode
            try(update mnode)catch()
        )
        catch
        (
            format "[FX_Weapon_Trail_bake v1.0] convertToPoly failed. Keeping Editable Mesh with hidden diagonals.\n"
        )
    )
    mnode
)

fn FXTB_GetSampleArrays pObjA pObjB startF endF sampleMode forceEval needB =
(
    local oldTime = sliderTime
    local arrA = #()
    local arrB = #()

    for f = startF to endF do
    (
        local pA = FXTB_GetNodePos pObjA f sampleMode forceEval
        append arrA pA
        if needB do
        (
            local pB = FXTB_GetNodePos pObjB f sampleMode forceEval
            append arrB pB
        )
    )

    try(sliderTime = oldTime)catch()
    try(redrawViews())catch()
    #(arrA, arrB)
)

fn FXTB_BuildRangeMesh pObjA pObjB startF endF widthSegs interp sampleMode forceEval applyMat makeDebug makeQuad =
(
    if pObjA == undefined do
    (
        messageBox "검기 폭 A 포인트를 먼저 선택해 주세요." title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )
    if pObjB == undefined do
    (
        messageBox "검기 폭 B 포인트를 먼저 선택해 주세요." title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )
    if endF <= startF do
    (
        messageBox "종료 프레임은 시작 프레임보다 커야 합니다." title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )
    if widthSegs < 1 do widthSegs = 1
    if interp < 0 do interp = 0

    clearListener()
    format "[FX_Weapon_Trail_bake v1.0 Mesh] Sample range: % ~ %\n" startF endF
    format "[FX_Weapon_Trail_bake v1.0 Mesh] Point A: %, Point B: %\n" pObjA.name pObjB.name

    local samples = FXTB_GetSampleArrays pObjA pObjB startF endF sampleMode forceEval true
    local firstPts = samples[1]
    local endPts = samples[2]

    for i = 1 to firstPts.count do
    (
        format "  frame % : pA %, pB %\n" (startF + i - 1) firstPts[i] endPts[i]
    )

    local startWidth = distance firstPts[1] endPts[1]
    local moveA = distance firstPts[1] firstPts[firstPts.count]
    local moveB = distance endPts[1] endPts[endPts.count]
    format "[FX_Weapon_Trail_bake v1.0 Mesh Check] start width: %, point A move: %, point B move: %\n" startWidth moveA moveB

    if startWidth < 0.001 do
    (
        messageBox "검기 폭 A/B 포인트의 폭이 거의 0입니다. 두 Point의 위치를 확인해 주세요." title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )

    if (moveA < 0.001 and moveB < 0.001) do
    (
        messageBox "입력한 구간에서 두 기준점의 위치 변화가 거의 없습니다.\n샘플 방식 또는 부모 연결 상태를 확인해 주세요." title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )

    if makeDebug do
    (
        FXTB_CreateDebugPoints firstPts "FX_Trail_A" FXTB_MeshAppDataID FXTB_MeshAppDataValue
        FXTB_CreateDebugPoints endPts "FX_Trail_B" FXTB_MeshAppDataID FXTB_MeshAppDataValue
    )

    local frameCount = endF - startF + 1
    local interpSegs = (frameCount - 1) * (interp + 1)
    local rowCount = interpSegs + 1
    local verts = #()
    local tverts = #()
    local triFaces = #()
    local quadFaces = #()

    for r = 0 to interpSegs do
    (
        local baseIdx = (r / (interp + 1)) as integer
        local subIdx = mod r (interp + 1)
        local fp = [0,0,0]
        local ep = [0,0,0]

        if subIdx == 0 then
        (
            local idx = baseIdx + 1
            fp = firstPts[idx]
            ep = endPts[idx]
        )
        else
        (
            local i = baseIdx + 1
            local rowT = (subIdx as float) / ((interp + 1) as float)
            local i1 = FXTB_ClampIndex (i-1) firstPts.count
            local i2 = FXTB_ClampIndex i firstPts.count
            local i3 = FXTB_ClampIndex (i+1) firstPts.count
            local i4 = FXTB_ClampIndex (i+2) firstPts.count
            fp = FXTB_CatmullRomSafe rowT firstPts[i1] firstPts[i2] firstPts[i3] firstPts[i4]
            ep = FXTB_CatmullRomSafe rowT endPts[i1] endPts[i2] endPts[i3] endPts[i4]
        )

        for c = 0 to widthSegs do
        (
            local u = (c as float) / (widthSegs as float)
            local v = if interpSegs == 0 then 0.0 else (r as float) / (interpSegs as float)
            append verts (FXTB_Linear fp ep u)
            append tverts [u, v, 0]
        )
    )

    local rowWidth = widthSegs + 1
    for r = 0 to (rowCount - 2) do
    (
        for c = 0 to (widthSegs - 1) do
        (
            local v1 = r * rowWidth + c + 1
            local v2 = v1 + 1
            local v3 = (r+1) * rowWidth + c + 1
            local v4 = v3 + 1
            append quadFaces #(v1, v3, v4, v2)
            append triFaces [v1, v3, v4]
            append triFaces [v1, v4, v2]
        )
    )

    local meshName = FXTB_GetNextName "FX_Trail_mash_"
    local mnode = FXTB_BuildTrailMeshNode meshName verts tverts triFaces makeQuad
    if mnode == undefined do
    (
        messageBox "메쉬 생성에 실패했습니다." title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )

    try(setAppData mnode FXTB_MeshAppDataID FXTB_MeshAppDataValue)catch()
    FXTB_ApplyRenderableSettings mnode
    if applyMat do mnode.material = FXTB_MakeMeshMaterial()

    try(update mnode)catch()
    select mnode
    completeRedraw()

    local faceLabel = if makeQuad then "사각 폴리" else "삼각 메쉬"
    local outFaceCount = if makeQuad then quadFaces.count else triFaces.count
    messageBox ("검기 메쉬 생성 완료\n\n이름: " + mnode.name + "\n출력 방식: " + faceLabel + "\n프레임: " + (startF as string) + " ~ " + (endF as string) + "\n정점 수: " + (verts.count as string) + "\n면 수: " + (outFaceCount as string)) title:"FX_Weapon_Trail_bake v1.0"
    mnode
)

fn FXTB_PrepareLinePoints posArray optimizeLine =
(
    local finalPts = #()
    if posArray.count < 1 do return finalPts

    if optimizeLine then
    (
        append finalPts posArray[1]
        for i = 2 to posArray.count do
        (
            if (distance posArray[i] finalPts[finalPts.count]) > 0.001 do append finalPts posArray[i]
        )
    )
    else
    (
        finalPts = posArray
    )

    if finalPts.count == 1 do
    (
        append finalPts (finalPts[1] + [0.01,0,0])
    )
    finalPts
)

fn FXTB_AddKnotCompat shp splineIndex knotType segType p inVec outVec =
(
    local ok = false

    try
    (
        addKnot shp splineIndex knotType segType p inVec outVec
        ok = true
    )
    catch
    (
        ok = false
    )

    if not ok do
    (
        try
        (
            addKnot shp splineIndex knotType segType p inVec
            ok = true
        )
        catch
        (
            ok = false
        )
    )

    if not ok do
    (
        try
        (
            addKnot shp splineIndex knotType segType p
            ok = true
        )
        catch
        (
            ok = false
        )
    )

    ok
)

fn FXTB_BuildLineShape lineName posArray renderableLine lineThickness optimizeLine lineMode =
(
    local finalPts = FXTB_PrepareLinePoints posArray optimizeLine
    if finalPts.count < 2 do return undefined

    local shp = splineShape name:lineName
    addNewSpline shp

    local knotType = #corner
    local segType = #line
    if lineMode == 2 do
    (
        knotType = #bezierCorner
        segType = #curve
    )

    for i = 1 to finalPts.count do
    (
        local p = finalPts[i]
        local inVec = p
        local outVec = p

        if lineMode == 2 do
        (
            local prevP = if i == 1 then finalPts[i] else finalPts[i-1]
            local nextP = if i == finalPts.count then finalPts[i] else finalPts[i+1]
            local tangent = nextP - prevP

            if (length tangent) > 0.0001 do
            (
                local handleLen = 0.25
                if i == 1 then handleLen = (distance p nextP) / 3.0
                else if i == finalPts.count then handleLen = (distance prevP p) / 3.0
                else handleLen = ((distance prevP p) + (distance p nextP)) / 6.0

                local dir = normalize tangent
                inVec = p - (dir * handleLen)
                outVec = p + (dir * handleLen)
            )
        )

        if not (FXTB_AddKnotCompat shp 1 knotType segType p inVec outVec) do
        (
            delete shp
            return undefined
        )
    )

    try(updateShape shp)catch()

    if lineMode == 2 do
    (
        try
        (
            for k = 1 to numKnots shp 1 do
            (
                setKnotType shp 1 k #bezierCorner
                try(setSegmentType shp 1 k #curve)catch()
            )
            updateShape shp
        )
        catch()
    )

    FXTB_ApplyLineRenderableSettings shp renderableLine lineThickness
    shp
)

fn FXTB_CollectInterpolatedLinePoints pObj startF endF interp sampleMode forceEval makeDebug debugPrefix =
(
    local samples = FXTB_GetSampleArrays pObj undefined startF endF sampleMode forceEval false
    local basePts = samples[1]

    if makeDebug do FXTB_CreateDebugPoints basePts debugPrefix FXTB_LineAppDataID FXTB_LineAppDataValue

    local frameCount = endF - startF + 1
    local interpSegs = (frameCount - 1) * (interp + 1)
    local linePts = #()

    for r = 0 to interpSegs do
    (
        local baseIdx = (r / (interp + 1)) as integer
        local subIdx = mod r (interp + 1)
        local p = [0,0,0]

        if subIdx == 0 then
        (
            local idx = baseIdx + 1
            p = basePts[idx]
        )
        else
        (
            local i = baseIdx + 1
            local rowT = (subIdx as float) / ((interp + 1) as float)
            local i1 = FXTB_ClampIndex (i-1) basePts.count
            local i2 = FXTB_ClampIndex i basePts.count
            local i3 = FXTB_ClampIndex (i+1) basePts.count
            local i4 = FXTB_ClampIndex (i+2) basePts.count
            p = FXTB_CatmullRomSafe rowT basePts[i1] basePts[i2] basePts[i3] basePts[i4]
        )
        append linePts p
    )
    #(basePts, linePts)
)


fn FXTB_BuildCrossPlaneLineMesh meshName posArray planeWidth optimizeLine applyMat =
(
    local finalPts = FXTB_PrepareLinePoints posArray optimizeLine
    if finalPts.count < 2 do return undefined
    if planeWidth < 0.001 do planeWidth = 0.001

    local halfW = planeWidth * 0.5
    local verts = #()
    local tverts = #()
    local faces = #()

    for i = 1 to finalPts.count do
    (
        local p = finalPts[i]
        local prevP = if i == 1 then finalPts[i] else finalPts[i-1]
        local nextP = if i == finalPts.count then finalPts[i] else finalPts[i+1]
        local tangent = nextP - prevP

        if (length tangent) < 0.0001 then tangent = [1,0,0] else tangent = normalize tangent

        local upRef = [0,0,1]
        if (abs (dot tangent upRef)) > 0.95 do upRef = [0,1,0]

        local side1 = cross tangent upRef
        if (length side1) < 0.0001 then side1 = [1,0,0] else side1 = normalize side1

        local side2 = cross tangent side1
        if (length side2) < 0.0001 then side2 = [0,0,1] else side2 = normalize side2

        local v = if finalPts.count <= 1 then 0.0 else ((i-1) as float) / ((finalPts.count-1) as float)

        append verts (p - side1 * halfW)
        append verts (p + side1 * halfW)
        append verts (p - side2 * halfW)
        append verts (p + side2 * halfW)

        append tverts [0, v, 0]
        append tverts [1, v, 0]
        append tverts [0, v, 0]
        append tverts [1, v, 0]
    )

    for i = 1 to (finalPts.count - 1) do
    (
        local b = (i-1) * 4
        local n = i * 4

        -- Plane 1
        append faces [b+1, n+1, n+2]
        append faces [b+1, n+2, b+2]

        -- Plane 2, crossed with Plane 1
        append faces [b+3, n+3, n+4]
        append faces [b+3, n+4, b+4]
    )

    local mnode = mesh vertices:verts faces:faces
    mnode.name = meshName
    FXTB_SetMeshUVs mnode tverts faces
    try(update mnode)catch()

    try(setAppData mnode FXTB_LineAppDataID FXTB_LineAppDataValue)catch()
    FXTB_ApplyRenderableSettings mnode
    if applyMat do mnode.material = FXTB_MakeLineMaterial()
    try(update mnode)catch()

    mnode
)

fn FXTB_BuildRangeLineForPoint pObj pointLabel startF endF interp sampleMode forceEval applyMat makeDebug lineMeshMode lineThickness optimizeLine lineMode =
(
    if pObj == undefined do return undefined
    if endF <= startF do
    (
        messageBox "종료 프레임은 시작 프레임보다 커야 합니다." title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )
    if interp < 0 do interp = 0
    if lineThickness < 0.001 do lineThickness = 0.001

    format "[FX_Weapon_Trail_bake v1.0 Line] Sample range: % ~ %\n" startF endF
    format "[FX_Weapon_Trail_bake v1.0 Line] Point %: %\n" pointLabel pObj.name

    local resultPts = FXTB_CollectInterpolatedLinePoints pObj startF endF interp sampleMode forceEval makeDebug ("FX_Trail_Line_" + pointLabel)
    local basePts = resultPts[1]
    local linePts = resultPts[2]

    for i = 1 to basePts.count do
    (
        format "  frame % : p% %\n" (startF + i - 1) pointLabel basePts[i]
    )

    local moveVal = distance basePts[1] basePts[basePts.count]
    format "[FX_Weapon_Trail_bake v1.0 Line Check] point % move: %\n" pointLabel moveVal

    if moveVal < 0.001 do
    (
        messageBox ("입력한 구간에서 검기 폭 " + pointLabel + " 포인트의 위치 변화가 거의 없습니다.\n샘플 방식 또는 부모 연결 상태를 확인해 주세요.") title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )

    local renderableLine = (lineMeshMode == 2)
    local outObjs = #()

    local lineName = FXTB_GetNextName "FX_Trail_line_"
    local lineObj = FXTB_BuildLineShape lineName linePts renderableLine lineThickness optimizeLine lineMode
    if lineObj == undefined do
    (
        messageBox ("검기 폭 " + pointLabel + " 포인트 라인 생성에 실패했습니다.") title:"FX_Weapon_Trail_bake v1.0"
        return undefined
    )

    try(setAppData lineObj FXTB_LineAppDataID FXTB_LineAppDataValue)catch()
    if applyMat do lineObj.material = FXTB_MakeLineMaterial()
    try(updateShape lineObj)catch()
    append outObjs lineObj

    if lineMeshMode == 3 do
    (
        local meshName = FXTB_GetNextName "FX_Trail_line_mesh_"
        local meshObj = FXTB_BuildCrossPlaneLineMesh meshName linePts lineThickness optimizeLine applyMat
        if meshObj != undefined then
        (
            append outObjs meshObj
        )
        else
        (
            messageBox ("검기 폭 " + pointLabel + " 포인트 십자가 플랜 메쉬 생성에 실패했습니다.") title:"FX_Weapon_Trail_bake v1.0"
        )
    )

    outObjs
)

try(closeRolloutFloater FXTB_Floater)catch()

rollout FXTB_MainRoll "FX_Weapon_Trail_bake v1.0"
(
    fn pointFilt obj = (obj != undefined and superclassof obj == Helper)

    label info_lbl "검기 폭 기준 오브젝트를 선택하세요." align:#center
    pickbutton pickA_btn "검기 폭 A 포인트" width:220 autoDisplay:true filter:pointFilt
    pickbutton pickB_btn "검기 폭 B 포인트" width:220 autoDisplay:true filter:pointFilt
    label line_info_lbl "라인은 A/B 중 선택된 포인트 기준으로 생성됩니다." align:#center

    groupBox range_grp "출력 프레임" pos:[10,112] width:250 height:82
    spinner start_spn "시작 프레임" range:[-100000,100000,0] type:#integer pos:[42,140] width:180
    spinner end_spn "종료 프레임" range:[-100000,100000,10] type:#integer pos:[42,168] width:180

    groupBox mesh_grp "메쉬 설정" pos:[10,202] width:250 height:120
    spinner width_spn "폭 방향 분할" range:[1,100,2] type:#integer pos:[50,230] width:172
    spinner interp_spn "프레임 보간" range:[0,50,1] type:#integer pos:[62,258] width:160
    checkbox quad_chk "사각 폴리로 생성" checked:true pos:[25,292]

    groupBox line_grp "라인 설정" pos:[10,330] width:250 height:174
    spinner line_interp_spn "라인 보간" range:[0,50,1] type:#integer pos:[62,358] width:160
    spinner thick_spn "라인 두께/플랜 폭" range:[0.001,10000,5.0] type:#float scale:0.1 pos:[62,386] width:160
    dropdownlist line_mode_dd "라인 생성 방식" items:#("직선 라인", "베지어 커브 편집용") selection:2 pos:[24,416] width:210
    dropdownlist line_mesh_dd "라인 메쉬 형태" items:#("생성 안 함", "실린더", "십자가 플랜") selection:3 pos:[24,454] width:210

    groupBox sample_grp "샘플 설정" pos:[10,522] width:250 height:96
    dropdownlist mode_dd "샘플 방식" items:#("부모 포함 좌표", "월드 좌표", "트랜스폼 위치", "원본 pos") selection:1 pos:[24,546] width:210
    checkbox force_chk "프레임 강제 평가" checked:true pos:[25,588]

    checkbox mat_chk "렌더용 기본 재질 적용" checked:true pos:[24,630]
    checkbox debug_chk "샘플 위치 확인 포인트 생성" checked:false pos:[24,654]
    checkbox opt_line_chk "라인 중복 포인트 정리" checked:true pos:[24,678]

    button create_mesh_btn "검기 메쉬 생성" width:230 height:36 pos:[15,712]
    button create_line_btn "검기 라인 생성" width:230 height:36 pos:[15,754]
    button del_mesh_btn "생성한 검기 메쉬 삭제" width:230 height:28 pos:[15,798]
    button del_line_btn "생성한 검기 라인 삭제" width:230 height:28 pos:[15,830]
    button del_all_btn "생성한 FX 오브젝트 모두 삭제" width:230 height:28 pos:[15,862]

    label ex_lbl "Time Configuration -> Custom -> FPS:(120~240)." align:#left pos:[15,900] width:250
    label ex4_lbl "생성 이름 예: FX_Trail_mash_001" align:#left pos:[15,920] width:250
    label ex5_lbl "라인 이름 예: FX_Trail_line_001" align:#left pos:[15,940] width:250

    on FXTB_MainRoll open do
    (
        start_spn.value = animationRange.start.frame as integer
        end_spn.value = animationRange.end.frame as integer
    )

    on pickA_btn picked obj do
    (
        FXTB_pickObjA = obj
        pickA_btn.text = obj.name
    )

    on pickB_btn picked obj do
    (
        FXTB_pickObjB = obj
        pickB_btn.text = obj.name
    )

    on create_mesh_btn pressed do
    (
        FXTB_BuildRangeMesh FXTB_pickObjA FXTB_pickObjB start_spn.value end_spn.value width_spn.value interp_spn.value mode_dd.selection force_chk.checked mat_chk.checked debug_chk.checked quad_chk.checked
    )

    on create_line_btn pressed do
    (
        local created = #()
        clearListener()

        if (FXTB_pickObjA == undefined and FXTB_pickObjB == undefined) then
        (
            messageBox "검기 라인을 생성하려면 검기 폭 A 포인트 또는 검기 폭 B 포인트를 하나 이상 선택해 주세요." title:"FX_Weapon_Trail_bake v1.0"
        )
        else
        (
            if FXTB_pickObjA != undefined do
            (
                local lineAObjs = FXTB_BuildRangeLineForPoint FXTB_pickObjA "A" start_spn.value end_spn.value line_interp_spn.value mode_dd.selection force_chk.checked mat_chk.checked debug_chk.checked line_mesh_dd.selection thick_spn.value opt_line_chk.checked line_mode_dd.selection
                if lineAObjs != undefined do for o in lineAObjs do append created o
            )
            if FXTB_pickObjB != undefined do
            (
                local lineBObjs = FXTB_BuildRangeLineForPoint FXTB_pickObjB "B" start_spn.value end_spn.value line_interp_spn.value mode_dd.selection force_chk.checked mat_chk.checked debug_chk.checked line_mesh_dd.selection thick_spn.value opt_line_chk.checked line_mode_dd.selection
                if lineBObjs != undefined do for o in lineBObjs do append created o
            )

            if created.count > 0 then
            (
                select created
                completeRedraw()
                local msg = "검기 라인 생성 완료\n\n"
                for i = 1 to created.count do msg += (created[i].name + "\n")
                msg += "\n프레임: " + (start_spn.value as string) + " ~ " + (end_spn.value as string)
                msg += "\n라인 생성 방식: " + line_mode_dd.items[line_mode_dd.selection]
                msg += "\n라인 메쉬 형태: " + line_mesh_dd.items[line_mesh_dd.selection]
                messageBox msg title:"FX_Weapon_Trail_bake v1.0"
            )
        )
    )

    on del_mesh_btn pressed do
    (
        local n = FXTB_DeleteByAppData FXTB_MeshAppDataID FXTB_MeshAppDataValue
        messageBox (("삭제 완료: " + (n as string) + "개")) title:"FX_Weapon_Trail_bake v1.0"
    )

    on del_line_btn pressed do
    (
        local n = FXTB_DeleteByAppData FXTB_LineAppDataID FXTB_LineAppDataValue
        messageBox (("삭제 완료: " + (n as string) + "개")) title:"FX_Weapon_Trail_bake v1.0"
    )

    on del_all_btn pressed do
    (
        local n = FXTB_DeleteAllCreated()
        messageBox (("삭제 완료: " + (n as string) + "개")) title:"FX_Weapon_Trail_bake v1.0"
    )
)

FXTB_Floater = newRolloutFloater "FX_Weapon_Trail_bake v1.0" 290 1040
addRollout FXTB_MainRoll FXTB_Floater
