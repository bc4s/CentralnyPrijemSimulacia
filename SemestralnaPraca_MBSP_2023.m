clear;
clc;
numberOfReplications = 100;
C = 4;   %pocet serverov
sumsOfDepartmentDoctorsWorkloadPercentage = zeros(C, 1);
sumsOfDepartmentAverageWaitingTimes = zeros(C, 1);

for r = 1:numberOfReplications
    centralQueue = [];                  %pociatocny rad po prichode do kliniky
    dentistQueue = [];                  %pociatocny rad po prichode k zubarovi
    orthopedistQueue = [];              %pociatocny rad po prichode k ortopedovi
    surgeonQueue = [];                  %pociatocny rad po prichode k chirurgovi
    
    currentCountCentral = [];
    currentCountDentist = [];
    currentCountOrthopedist = [];
    currentCountSurgeon = [];

    currentTimeCentral = [];
    currentTimeDentist = [];
    currentTimeOrthopedist = [];
    currentTimeSurgeon = [];

    simTime = 0;                        %simulacny cas
    workingTime = 600;                  %denny pracovny cas v minutach
    cal = zeros(C + 1, 2);              %inicializacia kalendara
    
    patientWaitingTimes = zeros(C, 1);
    numberOfPatients = zeros(C, 1);
    doctorsWorkload = zeros(C, 1);
    
    for i = 1:C + 1
        cal(i, 1) = 0;
        cal(i, 2) = intmax;
    end

    cal(C + 1, 2) = getArrivalTime(2);  %prichod prveho pacienta
    patientCounter = 1;                 %pocitame, kolko pacientov prislo do systemu

    while (simTime < workingTime || patientCounter > 0)
        %vyberame najblizsie udalost z kalendara
        [minTime, index] = getMinTime(cal);
        simTime = minTime;
    
        %odchod
        if (index < C + 1)
            if (index == 1)
                %odchod recepcia, urcime do, ktorej ambulancie pacient smeruje
                examinationIndex = getExaminationIndex();
    
                numberOfPatients(examinationIndex) = numberOfPatients(examinationIndex) + 1; 
                %ak je dana ambulancia volna, pacienta vysetrime
                if (cal(examinationIndex, 1) == 0)
                    cal(examinationIndex, 1) = 1;
                    examinationTime = getExaminationTime(examinationIndex);
                    cal(examinationIndex, 2) = simTime + examinationTime;
                    doctorsWorkload(examinationIndex) = doctorsWorkload(examinationIndex) + examinationTime;
                else
                    %ak ambulancia volna nie je, zaradime pacienta do
                    %prislusneho radu
                    if (examinationIndex == 2)
                        departmentQueueLength = length(dentistQueue);
                        dentistQueue(departmentQueueLength + 1) = simTime;
                        currentCountDentist(length(currentCountDentist) + 1) = departmentQueueLength;
                        currentTimeDentist(length(currentTimeDentist) + 1) = simTime;
                    elseif (examinationIndex == 3)
                        departmentQueueLength = length(orthopedistQueue);
                        orthopedistQueue(departmentQueueLength + 1) = simTime;
                        currentCountOrthopedist(length(currentCountOrthopedist) + 1) = departmentQueueLength;
                        currentTimeOrthopedist(length(currentTimeOrthopedist) + 1) = simTime;
                    else
                        if (rand() < 0.2)
                            % urgentny pacient sa predbehne
                            surgeonQueue = [simTime surgeonQueue];
                        else
                            departmentQueueLength = length(surgeonQueue);
                            surgeonQueue(departmentQueueLength + 1) = simTime;
                            currentCountSurgeon(length(currentCountSurgeon) + 1) = departmentQueueLength;
                            currentTimeSurgeon(length(currentTimeSurgeon) + 1) = simTime;
                        end
                    end
                end
    
                %ak caka niekto v rade pri prvom lekarovi, spracujeme ho
                [centralQueue, cal, waitingTime, doctorsWorkload] = processPatientFromQueue(centralQueue, cal, simTime, index, doctorsWorkload);
                currentCountCentral(length(currentCountCentral) + 1) = length(centralQueue);
                currentTimeCentral(length(currentTimeCentral) + 1) = simTime;
            elseif (index == 2)
                %odchod od zubara
                [dentistQueue, cal, waitingTime, doctorsWorkload] = processPatientFromQueue(dentistQueue, cal, simTime, index, doctorsWorkload);
                patientCounter = patientCounter - 1;
                currentCountDentist(length(currentCountDentist) + 1) = length(dentistQueue);
                currentTimeDentist(length(currentTimeDentist) + 1) = simTime;
            elseif (index == 3)
                %odchod od ortpeda
                [orthopedistQueue, cal, waitingTime, doctorsWorkload] = processPatientFromQueue(orthopedistQueue, cal, simTime, index, doctorsWorkload);
                patientCounter = patientCounter - 1;
                currentCountOrthopedist(length(currentCountOrthopedist) + 1) = length(orthopedistQueue);
                currentTimeOrthopedist(length(currentTimeOrthopedist) + 1) = simTime;
            else 
                %odchod chirurga
                [surgeonQueue, cal, waitingTime, doctorsWorkload] = processPatientFromQueue(surgeonQueue, cal, simTime, index, doctorsWorkload);
                patientCounter = patientCounter - 1;
                currentCountSurgeon(length(currentCountSurgeon) + 1) = length(surgeonQueue);
                currentTimeSurgeon(length(currentTimeSurgeon) + 1) = simTime;
            end
            patientWaitingTimes(index) = patientWaitingTimes(index) + waitingTime;
        %prichod
        else
    
            %ak je prvy pracovnik volny, spracovavame pacienta na prvom serveri
            if (cal(1, 1) == 0)
                cal(1, 1) = 1;
                examinationTime = getExamination(1, 4);
                cal(1, 2) = simTime + examinationTime;
                doctorsWorkload(1) = doctorsWorkload(1) + examinationTime;
           
            else
                %prvy pracovnik nie je volny, posleme pacienta do radu
                departmentQueueLength = length(centralQueue);
                centralQueue(departmentQueueLength + 1) = simTime;
                currentCountCentral(length(currentCountCentral) + 1) = departmentQueueLength;
                currentTimeCentral(length(currentTimeCentral) + 1) = simTime;
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
    doctorsWorkloadPercentage = zeros(C, 1);
    
    %==================== VYSTUP 2 ====================
    for i = 1:C
        percentage = (doctorsWorkload(i) / simTime) * 100;
        if (percentage > 100)
            percentage = 100;
        end
        doctorsWorkloadPercentage(i) = percentage;
    end
    
    %==================== VYSTUP 3 ====================

    totalPatients = 0;
    for i = 1:C
        totalPatients = totalPatients + numberOfPatients(i);
    end
    
    numberOfPatients(1) = totalPatients;
    
    %priemerna cakacia doba pacienta pacientov
    averageWaitingTimes = zeros(C, 1);
    for i = 1:C
        averageWaitingTimes(i) = patientWaitingTimes(i) / numberOfPatients(i);
    end

    for i = 1:C
        sumsOfDepartmentDoctorsWorkloadPercentage(i) = sumsOfDepartmentDoctorsWorkloadPercentage(i) + doctorsWorkloadPercentage(i);
        sumsOfDepartmentAverageWaitingTimes(i) = sumsOfDepartmentAverageWaitingTimes(i) + averageWaitingTimes(i);
    end
end

avgDepartmentDoctorsWorkloadPercentage = zeros(C, 1);
avgDepartmentWaitingTimes = zeros(C, 1);

for i = 1:C
    avgDepartmentDoctorsWorkloadPercentage(i) = sumsOfDepartmentDoctorsWorkloadPercentage(i) / numberOfReplications;
    avgDepartmentWaitingTimes(i) = sumsOfDepartmentAverageWaitingTimes(i) / numberOfReplications;
end

%==================== VYSTUP 1 ====================
plot(currentTimeCentral, currentCountCentral);
xlabel('Cas') 
ylabel('Pocet pacientov v rade') 
title('Graf zavislosti poctu pacientov v centralQueue na case') 
figure

plot(currentTimeDentist, currentCountDentist);
xlabel('Cas') 
ylabel('Pocet pacientov v rade') 
title('Graf zavislosti poctu pacientov v dentistQueue na case') 
figure
    
plot(currentTimeOrthopedist, currentCountOrthopedist);
xlabel('Cas') 
ylabel('Pocet pacientov v rade') 
title('Graf zavislosti poctu pacientov v orthopedistQueue na case') 
figure
    
plot(currentTimeSurgeon, currentCountSurgeon);
xlabel('Cas') 
ylabel('Pocet pacientov v rade') 
title('Graf zavislosti poctu pacientov v surgeonQueue na case') 
    
%==================== FUNKCIE ====================

%funckia pre zistenie ci nejaky pacient caka v rade
function [newQueue, newCal, waitingTime, newDoctorsWorkload] = processPatientFromQueue(queue, cal, simTime, index, doctorsWorkload)
     %ak caka niekto v rade pri prvom lekarovi, spracujeme ho
     if (length(queue) > 0)
         waitingTime = simTime - queue(1);
         cal(index,1) = 1;
         examinationTime = getExaminationTime(index);
         cal(index,2) = simTime + examinationTime;
         doctorsWorkload(index) = doctorsWorkload(index) + examinationTime;
         queue(1) = [];
      else
         %ak je rad prazdny, uvolnime server
         waitingTime = 0;
         cal(index, 1) = 0;
         cal(index, 2) = intmax;
     end

     newDoctorsWorkload = doctorsWorkload;
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