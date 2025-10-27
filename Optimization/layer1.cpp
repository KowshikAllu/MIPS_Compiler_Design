// assuming there is no empty spaces between labels

#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <algorithm>
using namespace std;

vector<vector<string>> tac;

vector<string> tokenize(string in){
    vector<string> res;
    string temp = "";
    for(int i=0; i<in.size(); i++){
        if(in[i] == ' '){
            res.push_back(temp);
            temp = "";
        }
        else
            temp += in[i];
    }
    if(temp.size())
        res.push_back(temp);
    return res;
}

void replace_label(string alpha, string beta){
    for(int i=0; i<tac.size(); i++){
        replace(tac[i].begin(), tac[i].end(), beta, alpha);
    }
}

void pop_label(int lineno){
    auto itr = tac.begin() + lineno;
    tac.erase(itr);
}

void label_optimize(){
    int lineno = 0;
    while(lineno != tac.size()-1){
        if(tac[lineno].size() && tac[lineno][0][0] == '#' && tac[lineno+1][0][0] == '#'){
            string primary_label = tac[lineno][0];
            primary_label.pop_back();
            string secondary_label = tac[lineno+1][0];
            secondary_label.pop_back();
            pop_label(lineno+1);
            replace_label(primary_label, secondary_label);
        }
        else{
            lineno++;
        }
    }
}

void save_tac(const string &filename){
    ofstream outfile(filename);
    for(auto &line : tac){
        for(auto &tok : line)
            outfile << tok << " ";
        outfile << "\n";
    }
    outfile.close();
}

int main(){
    fstream newfile;
    // newfile.open("../test-cases/optimize1.txt",ios::in);
    newfile.open("../output/tac.txt",ios::in);
    if (newfile.is_open()){
        string tp;
        while(getline(newfile, tp)){
            vector<string> temp;
            temp = tokenize(tp);
            tac.push_back(temp);
        }
        newfile.close();
    }

    // Save before optimization
    save_tac("bef_optimization.txt");

    // Apply optimization
    label_optimize();

    // Save after optimization
    save_tac("aft_optimization.txt");

    return 0;
}

// The function label_optimize() looks for two consecutive label definitions like:
// #L1:
// #L2:
// with no instructions between them, and merges them — so all references to #L2 are replaced with #L1, and the redundant label line (#L2) is deleted.

//! Before Optimization
// #L1:
// #L2:
// a = b + c
// goto #L2
// #L3:
// if a < b goto #L2
// #L2:
// return

//! After Optimization
// #L1:
// a = b + c
// goto #L1
// #L3:
// if a < b goto #L1
// #L1:
// return
