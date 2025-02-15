      MODULE MOD_UTILS
      CONTAINS

      SUBROUTINE PERROR(IOUT,ER1,ER2,ER3,ER4)

      IMPLICIT NONE
      INTEGER                      :: IOUT
      CHARACTER(LEN=*)             :: ER1
      CHARACTER(LEN=*), OPTIONAL   :: ER2
      CHARACTER(LEN=*), OPTIONAL   :: ER3
      CHARACTER(LEN=*), OPTIONAL   :: ER4

      WRITE(IOUT,*)'==================ERROR===========================', &
                   '======='
      WRITE(IOUT,*)ER1
      IF(PRESENT(ER2)) WRITE(IOUT,*)ER2
      IF(PRESENT(ER3)) WRITE(IOUT,*)ER3
      IF(PRESENT(ER4)) WRITE(IOUT,*)ER4
      WRITE(IOUT,*)'==================================================', &
                   '======='
      STOP
      RETURN

      END SUBROUTINE PERROR

      SUBROUTINE GET_TIMESTAMP(TS)
      CHARACTER(LEN=*)  TS
      CHARACTER(LEN=8)  D
      CHARACTER(LEN=10) T
                                                                                      
      CALL DATE_AND_TIME ( DATE=D,TIME=T )
      TS = D(7:8)//'/'//D(5:6)//'/'//D(1:4)//'   '//T(1:2)//':'//T(3:4)
      END SUBROUTINE GET_TIMESTAMP

      SUBROUTINE FOPEN(IUNIT,INSTR,IOPT) 
      IMPLICIT NONE
      INTEGER, INTENT(IN)             :: IUNIT
      CHARACTER(LEN=*)                :: INSTR 
      CHARACTER(LEN=3), INTENT(IN)    :: IOPT  
      CHARACTER(LEN=11) :: FORMSTR
      CHARACTER(LEN=7) :: STATSTR
      LOGICAL CHECK,FEXIST

      IF(IOPT(1:1) == "c")THEN  
       STATSTR = "old"
       CHECK = .TRUE.
      ELSE IF(IOPT(1:1) == "o") THEN 
       STATSTR = "unknown"
       CHECK = .FALSE.
      ELSE
       CALL PERROR(6,                 &
        "FIRST LETTER IN FOPEN OPTION STRING MUST BE 'c' OR 'o'")
      END IF
      IF(IOPT(2:2) == "f")THEN  
       FORMSTR = "formatted"
      ELSE IF(IOPT(2:2) == "u") THEN 
       FORMSTR = "unformatted"
      ELSE
       CALL PERROR(6,                 &
        "ERROR PROCESSING FOPEN ON FILE",INSTR,                    &
        "2ND LETTER IN FOPEN OPTION STRING MUST BE 'f' OR 'u'")
      END IF

      IF(CHECK)THEN
       INQUIRE(FILE=INSTR,EXIST=FEXIST)
       IF(.NOT. FEXIST)  CALL PERROR(6,"FILE "//INSTR//" NOT FOUND")
      END IF

      OPEN(IUNIT,FILE=INSTR,STATUS=TRIM(STATSTR),FORM=TRIM(FORMSTR)) 

      IF(IOPT(3:3) == "r")  REWIND(IUNIT)

      END SUBROUTINE FOPEN

      SUBROUTINE CRAY_SYSTEM_CALL(INSTRING)

      CHARACTER(LEN=*) :: INSTRING
      INTEGER :: ISTAT

      ISTAT = 0
# if defined (CRAY)
      ISTAT = ISHELL(TRIM(INSTRING))
# endif
      IF(ISTAT /= 0)THEN
      WRITE(IPT,*)'UNABLE TO COMPLETE COMMAND: '//TRIM(INSTRING)
      STOP
      END IF

      END SUBROUTINE CRAY_SYSTEM_CALL

      END MODULE MOD_UTILS

