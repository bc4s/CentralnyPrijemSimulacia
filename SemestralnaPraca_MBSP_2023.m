clear;
clc;
centralQueue = [];                  %pociatocny rad po prichode do kliniky
dentistQueue = [];                  %pociatocny rad po prichode k zubarovi
orthopedicQueue = [];               %pociatocny rad po prichode k ortopedovi
chirurgicQueue = [];                %pociatocny rad po prichode k chirurgovi

simTime = 0;                        %simulacny cas
workingTime = 600;                   %denny pracovny cas v minutach

C = 4;                              %pocet serverov
cal = zeros(C + 1, 2);              %inicializacia kalendara

for i=1:C+1
    cal(i,1) = 0;
    cal(i,2) = intmax;
end

cal(C + 1, 2) = getArrivalTime(2);  %prichod prveho pacienta
patientCounter = 1;                 %pocitame, kolko pacientov prislo do systemu
urgentPatient = 0;
isUrgentPatient = false;

while (simTime < workingTime || patientCounter > 0)
    %vyberame najblizsie udalost z kalendara
    [minTime, index] = getMinTime(cal);
    simTime = minTime;

    %odchod
    if (index < C + 1)
        if (index == 1)
            %odchod recepcia,, urcime do, ktorej ambulancie pacient smeruje
            examinationIndex = getExaminationIndex();

            if (examinationIndex == 4 && rand() < 0.2)
                isUrgentPatient = true;
                urgentPatient = urgentPatient + 1;
            end

            %ak je dana ambulancia volna, pacienta vysetrime
            if (cal(examinationIndex, 1) == 0)
                cal(examinationIndex, 1) = 1;
                cal(examinationIndex, 2) = simTime + getExaminationTime(examinationIndex);
            else
                %ak ambulancia volna nie je, zaradime pacienta do
                %prislusneho radu
                if (examinationIndex == 2)
                    actLenght = length(dentistQueue);
                    dentistQueue(actLenght+1) = simTime;
                elseif (examinationIndex == 3)
                    actLenght = length(orthopedicQueue);
                    orthopedicQueue(actLenght+1) = simTime;
                else
                    if (isUrgentPatient)
                        % urgentny pacient sa predbehne
                        chirurgicQueue = [simTime chirurgicQueue];
                        isUrgentPatient = false;
                    else
                        actLenght = length(chirurgicQueue);
                        chirurgicQueue(actLenght+1) = simTime;
                    end
                end
            end

            %ak caka niekto v rade pri prvom lekarovi, spracujeme ho
            [centralQueue, cal] = processPatientFromQueue(centralQueue, cal, simTime, index);

        elseif (index == 2)
            %odchod od zubara
            [dentistQueue,cal] = processPatientFromQueue(dentistQueue, cal, simTime, index);
            patientCounter = patientCounter - 1;
        elseif (index == 3)
            %odchod od ortpeda
            [orthopedicQueue, cal] = processPatientFromQueue(orthopedicQueue, cal, simTime, index);
            patientCounter = patientCounter - 1;
        else 
            %odchod chirurga
            [chirurgicQueue, cal] = processPatientFromQueue(chirurgicQueue, cal, simTime, index);
            patientCounter = patientCounter - 1;
        end
        
    %prichod
    else

        %ak je prvy pracovnik volny, spracovavame pacienta na prvom serveri
        if (cal(1, 1) == 0)
            cal(1,1) = 1;
            cal(1, 2) = simTime + getExamination(1,4);
       
        else
            %prvy pracovnik nie je volny, posleme pacienta do radu
            actLength = length(centralQueue);
            centralQueue(actLength+1) = simTime;
        end

        %s prichodom vygenerujeme noveho pacienta
        if (simTime <= 60)
            arrivalTime = getArrivalTime(2) + simTime;
        elseif(simTime > 60 && simTime <= 300)
            arrivalTime = getArrivalTime(5) + simTime;
        elseif(simTime > 300 && simTime <= 420)
            arrivalTime = getArrivalTime(3) + simTime;
        else
            arrivalTime = getArrivalTime(9) + simTime;
        end      

        %ak je po pracovnej dobe, tak novy prichod pacienta neplanujem
        if (arrivalTime > workingTime)
            cal(C + 1, 2) = intmax;
        else
            cal(C + 1, 2) = arrivalTime;
            patientCounter = patientCounter + 1;
        end

       
    end
end
%TODO
%Treba spravit kalendar udalosti pre prichod pacientov do systemu, ako ich
%vybavuje pracovnik, do radu budeme zapisovat len tych pacientov, ktori
%realne cakaju v rade na vybavenie pracovnikom

%funckia pre zistenie ci nejaky pacient caka v rade
function [newQueue, newCal] = processPatientFromQueue(queue, cal, simTime, index)
     %ak caka niekto v rade pri prvom lekarovi, spracujeme ho
     if (length(queue) > 0)
%        waitingTimeOfPatient = simTime - queue(1);
         cal(index,1) = 1;
         cal(index,2) = simTime + getExaminationTime(index);
         queue(1) = [];
      else
         %ak je rad prazdny, uvolnime server
         cal(index, 1) = 0;
         cal(index, 2) = intmax;
     end

     newQueue = queue;
     newCal = cal; 
end

%funkcia na generovanie prichodov do polikliniky
function arrivalTime = getArrivalTime(timeOffset)
    arrivalTime = exprnd(timeOffset);
end

%funkcia na generovanie trvania vysetrenia pacientov na jednotlivych
%servevoch
function examination = getExamination(lower, upper)
    distribution = makedist('Uniform','lower',lower,'upper',upper);
    examination = random(distribution,1,1);
end

%funkcia na zistenie casu vysetrenia pacienta
function examinationTime = getExaminationTime(index)
    if (index == 1)
        examinationTime = getExamination(1,4); %pracovnik
    elseif (index == 2)
        examinationTime = getExamination(20, 40); %zubar
    elseif (index == 4)
        examinationTime = getExamination(5, 25); %chirurg
    else
        examinationTime = getExamination(10, 20); %ortoped
    end  
end

%funkcia na zistenie typu doktora, ku ktoremu pacient ide
function examinationIndex = getExaminationIndex()
    randNumber = rand();
    if (randNumber < 0.1)
        examinationIndex  = 2; %zubar
    elseif (randNumber < 0.5)
        examinationIndex  = 4; %chirurg
        if (rand() < 0.2)
            
        end
    else
        examinationIndex  = 3; %ortoped
    end
end

%funcia na zistenie minima a jeho indexu v kalendari
function [min, index] = getMinTime(cal)
    x = intmax;
    for i = 1:length(cal)
        if (cal(i,2) < x)
            x = cal(i,2);
            index = i;
        end
    end
    min = x;
end

