classdef Excel2Lookup <handle
    % Creates nD Lookup tables with excel csv data.
    % All data needs to be in columns and has to be unique breakpoints.
    properties
        tables
        breakPoints
        info
        fileName
        rawData
    end
    
    methods
        function obj = Excel2Lookup(varargin)
            if nargin == 0
                obj.fileName = uigetfile("*.csv","Select .csv file.");
            else
                obj.fileName = varargin{1};
            end
            obj.ReadData();
            obj.CreateBreakPoints();
            obj.CreateTables();
            obj.CreateInfos();
        end
        
        function ReadData(obj)
            obj.rawData = readtable(obj.fileName);
        end
        function CreateBreakPoints(obj)
            list = obj.rawData.Properties.VariableNames;
            [inputIndx,tf] = listdlg('ListString',list,'SelectionMode','multiple','PromptString','Select Inputs');
            outputIndx = 1:length(list);

            if tf
                for i = 1:length(inputIndx)
                    outputIndx(inputIndx(i) == outputIndx) = [];
                end
                obj.breakPoints.bpNames = obj.rawData.Properties.VariableNames(inputIndx);
                obj.tables.tableNames = obj.rawData.Properties.VariableNames(outputIndx);
                
                dataLength = 1;
                for i = 1:length(inputIndx)
                    selectedBpName = obj.breakPoints.bpNames{i};
                    bps = unique(obj.rawData.(obj.breakPoints.bpNames{i})');
                    evalText = "obj.breakPoints." + string(selectedBpName) + "= bps;";
                    eval(evalText);
                    dataLength = dataLength*length(bps);                    
                end
                [rn,cn] = size(obj.rawData);
                if (dataLength ~= (rn))
                    error("Table size and breakpoint lengths is not matching! Check tables.");
                end
            end
        end
        function CreateTables(obj)
            tableSize = [];
            for i = 1:length(obj.breakPoints.bpNames)
                selectedBpName = obj.breakPoints.bpNames{i};
                tableSize = [tableSize,length(obj.breakPoints.(selectedBpName))];
            end
            
            for i = 1:length(obj.tables.tableNames)
                placeHolderTable = NaN(tableSize);
                selectedTableName = obj.tables.tableNames{i};
                evalText = "obj.tables." + string(selectedTableName) + " = placeHolderTable;";
                eval(evalText);
            end
          
            for i = 1:length(obj.tables.tableNames)
                selectedTableName = obj.tables.tableNames{i};
                selectedTable = obj.tables.(selectedTableName);
                for j = 1:prod(tableSize)
                    selectedData = obj.rawData.(selectedTableName)(j);
                    evalText  = "selectedTable(";
                    for k = 1:length(obj.breakPoints.bpNames)
                        selectedBPName = obj.breakPoints.bpNames{k};
                        selectedBP = obj.rawData.(selectedBPName)(j);
                        curIdx = find(obj.breakPoints.(selectedBPName) == selectedBP);
                        if k == length(obj.breakPoints.bpNames)
                            evalText = evalText + num2str(curIdx)+") = selectedData;";
                        else
                            evalText = evalText + num2str(curIdx) +",";
                        end
                    end
                eval(evalText);
                end
                obj.tables.(selectedTableName) = selectedTable;
            end
            obj.tables.tableSize = tableSize;
        end
        function CreateInfos(obj)
            obj.info = "Breakpoints has same order with breakPoints.breakpointName property.";
        end
        function ValidateData(obj)
            fig = figure;
            fig.Color = [1,1,1];
            tiledlayout("flow");
            for i = 1:length(obj.tables.tableNames)
                selectedTableName = obj.tables.tableNames{i};
                v = obj.tables.(selectedTableName);
                evalInterpnText = "data = interpn(";
                evalInterpnTextLast = ");";
                for j = 1:length(obj.breakPoints.bpNames)
                    selectedBPName = obj.breakPoints.bpNames{j};
                    bpEvalText = "bp" + num2str(j) + " = obj.breakPoints.(selectedBPName);";
                    inputEvalText = "i" + num2str(j) + " = obj.rawData.(selectedBPName);";
                    if j == length(obj.breakPoints.bpNames)
                        evalInterpnText  = evalInterpnText + "bp" + num2str(j) + ",v";
                        
                    else
                        evalInterpnText  = evalInterpnText + "bp" + num2str(j) + ",";
                        
                    end
                    evalInterpnTextLast  = ",i" + num2str(length(obj.breakPoints.bpNames)-j+1) + evalInterpnTextLast;
                    eval(bpEvalText);
                    eval(inputEvalText);
                    
                end
                eval(evalInterpnText + evalInterpnTextLast);
                y = data - obj.rawData.(selectedTableName);

                nexttile;
                plot(y);
                title(selectedTableName);
                ylabel("Error");
                xlabel("Data Point");
                
               
                
            end
          
        end
    end
end

