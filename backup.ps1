# CICD -> gitlab-jenkins-cicd-lab (GitHub) 스냅샷 백업
# 방향은 항상 CICD -> gitlab-jenkins-cicd-lab 한쪽만. 삭제는 gitlab-jenkins-cicd-lab 안에서만 일어난다.
#
# 최초 1회:  .\backup.ps1 -UserName "이름" -UserEmail "메일" -RemoteUrl "https://github.com/<계정>/gitlab-jenkins-cicd-lab.git"
# 이후:      .\backup.ps1

param(
    [string]$UserName,
    [string]$UserEmail,
    [string]$RemoteUrl
)

$Src = 'C:\Users\NB-25072832\Desktop\junhyeong.lee\CICD'
$Dst = 'C:\Users\NB-25072832\Desktop\junhyeong.lee\gitlab-jenkins-cicd-lab'

function Fail($msg) {
    Write-Host "오류: $msg" -ForegroundColor Red
    exit 1
}

# git 명령을 실행하고 실패하면 멈춘다
function Invoke-Git {
    & git.exe -C $Dst @args
    if ($LASTEXITCODE -ne 0) { Fail "git $($args -join ' ') 실패 (종료 코드 $LASTEXITCODE)" }
}

# --- 0. 안전 점검: 원본과 대상이 서로 겹치면 /MIR 이 원본을 지울 수 있다 ---
$srcFull = [IO.Path]::GetFullPath($Src).TrimEnd('\')
$dstFull = [IO.Path]::GetFullPath($Dst).TrimEnd('\')
if (-not (Test-Path $srcFull)) { Fail "원본 폴더가 없습니다: $srcFull" }
if ($dstFull -eq $srcFull -or
    $dstFull.StartsWith($srcFull + '\', [StringComparison]::OrdinalIgnoreCase) -or
    $srcFull.StartsWith($dstFull + '\', [StringComparison]::OrdinalIgnoreCase)) {
    Fail "원본과 대상 폴더가 겹칩니다. 중단합니다."
}

# --- 1. 최초 1회 세팅 ---
if (-not (Test-Path "$Dst\.git")) {
    if (-not ($UserName -and $UserEmail -and $RemoteUrl)) {
        Fail "최초 실행입니다. -UserName, -UserEmail, -RemoteUrl 을 모두 지정하세요."
    }
    Write-Host "== 최초 세팅 ==" -ForegroundColor Cyan
    New-Item -ItemType Directory -Force $Dst | Out-Null
    Invoke-Git init -b main
    Invoke-Git config --local user.name $UserName
    Invoke-Git config --local user.email $UserEmail
    Invoke-Git remote add origin $RemoteUrl
}

# --- 2. 복사 (제외: .git, build, .gradle) ---
Write-Host "== 복사: $srcFull -> $dstFull ==" -ForegroundColor Cyan
robocopy $srcFull $dstFull /MIR /XD .git build .gradle /R:1 /W:1 /NFL /NDL /NP
if ($LASTEXITCODE -ge 8) { Fail "robocopy 실패 (종료 코드 $LASTEXITCODE)" }
Write-Host "robocopy 종료 코드 $LASTEXITCODE (0~7 은 정상)"

# --- 3. 제외 설정 검사 ---
Write-Host "== 제외 설정 검사 ==" -ForegroundColor Cyan
$extraGit = Get-ChildItem $dstFull -Recurse -Force -Filter '.git' |
    Where-Object { $_.FullName -ne "$dstFull\.git" }
$extraBuild = Get-ChildItem $dstFull -Recurse -Force -Directory |
    Where-Object { ($_.Name -in 'build', '.gradle') -and $_.FullName -notlike "$dstFull\.git\*" }
if ($extraGit) {
    $extraGit | ForEach-Object { Write-Host "  남아 있는 .git: $($_.FullName)" -ForegroundColor Red }
    Fail ".git 이 최상위 한 개가 아닙니다. 중단합니다."
}
if ($extraBuild) {
    $extraBuild | ForEach-Object { Write-Host "  남아 있는 폴더: $($_.FullName)" -ForegroundColor Red }
    Fail "build 또는 .gradle 폴더가 남아 있습니다. 중단합니다."
}
Write-Host "OK: .git 은 최상위 한 개뿐이고 build, .gradle 은 없습니다." -ForegroundColor Green

# --- 4. 변경 확인 ---
Invoke-Git add -A
$changes = & git.exe -C $Dst status --porcelain
if (-not $changes) {
    Write-Host "변경 사항이 없습니다. 커밋하지 않고 종료합니다."
    exit 0
}
Write-Host "== 변경된 파일 ==" -ForegroundColor Cyan
Invoke-Git status --short

$answer = Read-Host "커밋하고 push 할까요? (y 입력 시 진행)"
if ($answer -ne 'y') {
    Write-Host "취소했습니다. (add 만 된 상태입니다. 다음 실행 때 다시 비교합니다)"
    exit 0
}

# --- 5. 커밋과 push ---
$msg = "snapshot " + (Get-Date -Format 'yyyy-MM-dd HH:mm')
Invoke-Git commit -m $msg
Invoke-Git push -u origin main
Write-Host "완료: $msg" -ForegroundColor Green
