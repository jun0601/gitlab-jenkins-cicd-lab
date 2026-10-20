# practice-app

환경: Java 8, Gradle 7.6.4 (로컬: gradlew, CI: gradle 이미지). 모듈: base-core, mod-a(→core), mod-b(→core), mod-c
로컬 확인: `.\gradlew.bat buildArchives` → 각 모듈 `dist\*.jar` 생성

## 학습 목표
흐름 이해 → 도구 익숙해지기 → 브랜치 나눠 보기. CI 파일은 회사 구조를 단순화한 "동작하는 버전"이고, 읽고 작게 고쳐 보며 익힌다.

## 단계
- [ ] 1. 읽기: practice-ci-common 의 공통 파일을 읽고 app 의 .gitlab-ci.yml 과 연결(include/extends)을 설명할 수 있다
- [ ] 2. main push → compile:only 만 초록색
- [ ] 3. feature/xxx 브랜치에서 mod-a 만 수정 → 로그의 "Build Project List : mod-a"
- [ ] 4. dev, uat push → compile:artifacts + publish + (uat) deploy 모의 job 실행, Job artifacts 로 jar 다운로드
- [ ] 5. 태그 v1.0.0 → compile:artifacts → publish → deploy:prod → merge:release 순서 실행
- [ ] 6. (나중) 모의 deploy 를 Jenkins(Docker) curl 호출로 교체
- [ ] 7. (나중) Tomcat(Docker) 배포
