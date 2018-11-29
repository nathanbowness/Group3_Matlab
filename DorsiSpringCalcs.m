classdef DorsiSpringCalcs
    properties
       % Material Properties
        YoungsModulus = 200000000000; % Young's Modulus - Steel [Pa]
        ShearModulus = 79300000000; % Shear Modulus  - Steel
        Density = 7850; % kg/m^3
        A = 140000; % Area from Shigley table 10-4
        m = 0.19; % Constant from Shigley table 10-4
        
        % Spring dimensions
        NumberBodyTurns = 15;
        wireDiameterSpring
        meanDiameterCoil
        
        R1
        R2
        curlAngle = 330; %how "curled" in the end hooks are
        
        %% Put the Neutral of the graph
        neutralLengthIndex = 9;
        neutralLengthValue;
        
        
        %% Calculated to return
        k
        lengthUnstrechedSpring
        weightExtensionSpring
        extensionCableLength 
        totalLengthUnstrechedSpring
    end
    methods
        
        function obj = DorsiSpringCalcs(personHeight, dorsiSpringLengthArray)
            %% Design variables
            obj.wireDiameterSpring = 0.0012/1.78*personHeight; % Diameter of wire
            d = UnitConversion.Meters2Inches(obj.wireDiameterSpring); 
            
            obj.meanDiameterCoil = 0.007/1.78*personHeight; % Mean diameter of coil
            D = UnitConversion.Meters2Inches(obj.meanDiameterCoil); 
            
            E = UnitConversion.Pa2Psi(obj.YoungsModulus);
            G = UnitConversion.Pa2Psi(obj.ShearModulus);  
            Fi = UnitConversion.Newton2Lbf(5.29/1.78*personHeight); %Initial tension force in spring
            
            obj.R1 = obj.meanDiameterCoil/2;
            R1 = UnitConversion.Meters2Inches(obj.R1); 
            obj.R2 = obj.meanDiameterCoil/2;
            R2 = UnitConversion.Meters2Inches(obj.R2);
            
            %% Length of the dorsiflexion spring - find from array -- use dorsiSpringLengthArray
            maxLength = max(dorsiSpringLengthArray);
            minLength = min(dorsiSpringLengthArray);
            % Position where the second highest peek occurs -- will need to change 
            % if the placement of pulleys changes
            neutralLength = dorsiSpringLengthArray(obj.neutralLengthIndex);
            obj.neutralLengthValue = neutralLength;

            LtotO = UnitConversion.Meters2Inches(neutralLength);

            %Bring in y value [m]
            Lmax = UnitConversion.Meters2Inches(maxLength);
            y = Lmax-LtotO;
            
            %% Calculations   
            %Calculate number of active turns
            Na = obj.NumberBodyTurns+(G/E);
            %Calculate the linear spring constant
            k = (d.^4)*(G)/(8*(D.^3)*Na);
            %Calculate spring index
            c = D/d;
            %Calculate original spring length
            Lo = (2*c-1+obj.NumberBodyTurns)*d;
            %Calculate new spring length
            L = Lo + y;
            %Calculate cable length
            CL = LtotO-(Lo+4*R1);
            %Calculate Bergstrasser factor
            Kb = (4*c+2)/(4*c-3);
            %Calculate maximum force applied
            Fmax = Fi + k*y;
            %Minimum force
            Fmin = Fi;
            %Calculate cyclic force amplitude
            Fa = (Fmax-Fmin)/2;
            %Calculate cyclic force mean
            Fm = (Fmax+Fmin)/2;
            %Calculate shear stress amplitude
            TauA = 8*Kb*Fa*D/(pi*(d.^3));
            %Calculate shear stress mean
            TauM = Fm/Fa*TauA;    
            %Calculate Ultimate strength 
            Sut = obj.A/(d.^obj.m); 
            %Calculate Ssy - eq'n from Shigley table 10-7
            Ssy = 0.45*Sut;
            %Calculate Sy - eq'n from Shigley table 10-7
            Sy = 0.75*Sut;
            %Calculate ultimate shear strength Ssu
            Ssu = 0.67*Sut;

            Ssa = UnitConversion.Pa2Psi(241000000); %[Pa] from Zimmerli data  
            Ssm = UnitConversion.Pa2Psi(379000000); %[Pa] from Zimmerli data

            %CASE 1 ANALYSIS - Coil fatigue failure

                %Get modified endurance limit
                Sse = (Ssa)/(1-((Ssm/Ssu).^2));
            nCase1 = (1/2)*((Ssu/TauM).^2)*(TauA/Sse)*(-1+((1+(((2*TauM*Sse)/(Ssu*TauA)).^2)).^(1/2)));

            %CASE 2 ANALYSIS - Coil yielding failure  
                %Get torsional stress caused by initial tension
                 TauI = 8*Kb*Fi*D/(pi*(d.^3));

                 r = TauA/(TauM-TauI);
                 Ssay = (r/(r+1))*(Ssy-TauI);
                 nCase2 = Ssay/TauA;

            %CASE 3 ANALYSIS - End-hook bending fatigue failure (at location A)
            c1 = 2*R1/d;
            kA = (4*(c1.^2)-c1-1)/(4*c1*(c1-1));
            SigmaA = Fa*(kA*((16*D)/(pi*(d.^3)))+(4/(pi*(d.^2))));
            SigmaM = Fm/Fa*SigmaA;
            Se = Sse/0.577;
            nCase3 = (1/2)*((Sut/SigmaM).^2)*(SigmaA/Se)*(-1+((1+(((2*SigmaM*Se)/(Sut*SigmaA)).^2)).^(1/2)));

            %CASE 4 ANALYSIS - End-hook torsional fatigue failure (at location B)
            c2 = 2*R2/d;
            kB = (4*c2-1)/(4*c2-4);
            TauAB = Fa*kB*8*D/(pi*(d.^3));
            TauMB = Fm/Fa*TauAB;
            nCase4 = (1/2)*((Ssu/TauMB).^2)*(TauAB/Sse)*(-1+((1+(((2*TauMB*Sse)/(Ssu*TauAB)).^2)).^(1/2)));

            %convert variables to SI units
            D = round(UnitConversion.Inches2Meters(D),6); 
            d = UnitConversion.Inches2Meters(d); 
            E = UnitConversion.Psi2Pa(E); 
            G = UnitConversion.Psi2Pa(G);
            R1 = UnitConversion.Inches2Meters(R1); 
            R2 = UnitConversion.Inches2Meters(R2); 
            Fi = UnitConversion.Lbf2Newton(Fi); 
            Lo = UnitConversion.Inches2Meters(Lo);
            obj.lengthUnstrechedSpring = Lo;
            obj.totalLengthUnstrechedSpring = Lo + 4*R1;
            
            L = UnitConversion.Inches2Meters(L);
            y = UnitConversion.Inches2Meters(y);
            k = UnitConversion.PoundFperInch2NewtonperMeter(k);
            obj.k = k; % Set k in SI units
            Lmax = UnitConversion.Inches2Meters(Lmax);
            LtotO = UnitConversion.Inches2Meters(LtotO);
            CL = UnitConversion.Inches2Meters(CL);
            Fmax = UnitConversion.Lbf2Newton(Fmax);
            Fmin = UnitConversion.Lbf2Newton(Fmin);
            Fa = UnitConversion.Lbf2Newton(Fa);
            Fm = UnitConversion.Lbf2Newton(Fm);
            TauA = UnitConversion.Psi2Pa(TauA);
            TauM = UnitConversion.Psi2Pa(TauM);  
            Sut = UnitConversion.Psi2Pa(Sut);
            Ssy = UnitConversion.Psi2Pa(Ssy);
            Sy = UnitConversion.Psi2Pa(Sy);
            Ssu = UnitConversion.Psi2Pa(Ssu);
            Ssa = UnitConversion.Psi2Pa(Ssa);
            Ssm = UnitConversion.Psi2Pa(Ssm);
            Sse = UnitConversion.Psi2Pa(Sse);    
            TauI = UnitConversion.Psi2Pa(TauI);
            Ssay = UnitConversion.Psi2Pa(Ssay);
            SigmaA = UnitConversion.Psi2Pa(SigmaA);
            SigmaM = UnitConversion.Psi2Pa(SigmaM);
            Se = UnitConversion.Psi2Pa(Se);
            TauAB = UnitConversion.Psi2Pa(TauAB);
            TauMB = UnitConversion.Psi2Pa(TauMB);

            obj.weightExtensionSpring = GetWeightExtension(obj, d, R1);
            obj.extensionCableLength = CL;
            
            
            fileID = fopen('C:\MCG4322B\Group3\Solidworks\Equations\dorsiSpringDimensions.txt','w');
                fprintf(fileID, '"dDorsiSpringCoil"= %f\n', D);
                fprintf(fileID, '"dDorsiSpringWire"= %f\n', d);
                fprintf(fileID, '"r1DorsiSpring"= %7.7f\n', D/2);
                fprintf(fileID, '"r2DorsiSpring"= %7.7f\n', D/2);
                fprintf(fileID, '"LoDorsiSpring"= %f\n', Lo);
                fprintf(fileID, '"numBodyTurnsDorsiSpring"= %f\n', obj.NumberBodyTurns);
            fclose(fileID);
            
            
        end
        
        function MomentSI = GetMomentContribution(obj, currentSpringCableLength, ...
                currentDorsiFlexionSpringPosition, maxDorsiLength, maxValueIndex, i)
            %% Current Position Moment
            yCurrent = (currentSpringCableLength-obj.extensionCableLength-(obj.lengthUnstrechedSpring + (4*obj.R1)));
            % Negative values are the distances being picked up by the cam - slack region
            
            if(yCurrent > 0)
                % Loading spring
                
                if(maxValueIndex < i)
                    
                    % Spring pulling toe
                    yMax = (maxDorsiLength-obj.extensionCableLength-(obj.lengthUnstrechedSpring + (4*obj.R1)));
                    yCurrent = yCurrent-yMax;
                end 
            
                currentFy = obj.k*yCurrent*sin(deg2rad(currentDorsiFlexionSpringPosition.AppliedToeCableForceAngle));
                currentFx = obj.k*yCurrent*cos(deg2rad(currentDorsiFlexionSpringPosition.AppliedToeCableForceAngle));
                currentMoment = currentFy*currentDorsiFlexionSpringPosition.distanceFromAnkle2ToeCableX + currentFx*currentDorsiFlexionSpringPosition.distanceFromAnkle2ToeCableY;            
                
                %% Next Position Moment
                %yNext = (nextSpringCableLength-obj.extensionCableLength-(obj.lengthUnstrechedSpring + (4*obj.R1)));
                %nextFy = obj.k*yNext*sin(deg2rad(nextDorsiFlexionSpringPosition.AppliedToeCableForceAngle));
                %nextFx = obj.k*yNext*cos(deg2rad(nextDorsiFlexionSpringPosition.AppliedToeCableForceAngle));

                %nextMoment = nextFy*nextDorsiFlexionSpringPosition.distanceFromAnkle2ToeCableX + nextFx*nextDorsiFlexionSpringPosition.distanceFromAnkle2ToeCableY;

                %% Next Moment
                MomentSI = (currentMoment);%(nextMoment- currentMoment);
            else
                MomentSI = 0;
            end
        end
        
        function weight = GetWeightExtension(obj, d, R1)
            V = pi*(d.^2)/4*(obj.NumberBodyTurns+2*obj.curlAngle*R1);%Units in meters and rads
            weight = V*obj.Density; %Units in Kg
        end 
    end
end