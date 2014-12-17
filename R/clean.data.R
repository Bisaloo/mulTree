##########################
#Cleans a table/tree to match with a given table/tree
##########################
#v0.1
##########################
#SYNTAX :
#<taxon> A vector containing a list of taxon names.
#<data> A data.frame, matrix, phylo or multiPhylo object
#<tree> A phylo or multiPhylo object
#----
#guillert(at)tcd.ie - 17/12/2014
##########################
#Requirements:
#-R 3
#-R package "geiger"
##########################

clean.data<-function(taxon, data, tree) {

#HEADER
    require(caper)

#DATA INPUT

    #taxon
    if (class(taxon) == 'numeric') {
        #taxon is a column number
        check.length(taxon, 1, " must be a single \"numerical\" value referring to the column containing the taxon names in \"data\".")
        taxon_column<-TRUE
        taxon_number<-TRUE

    } else {

        check.class(taxon, 'character', " must be a \"character\" value referring to the column containing the taxon names in \"data\".")
        if(length(taxon) == 1) {
            #taxon is a column name
            taxon_column<-TRUE
            taxon_number<-FALSE

        } else {

            #taxon is a vector
            for (vector_length in 0:3) {check.length(taxon, vector_length,  " must be a \"character\" value referring to the column containing the taxon names in \"data\".")}
            taxon_column<-FALSE
        }
    }

    #data (must be a data.frame or a matrix)
    data_class<-check.class(data, c('data.frame', 'matrix'), " must be a \"data.frame\" or \"matrix\" object.")   

    #data (must be a data.frame or a matrix)
    tree_class<-check.class(tree, c('phylo', 'multiPhylo'), " must be a \"phylo\" or \"multiPhylo\" object.")   

    #is provided column present in data?
    if(taxon_column == TRUE) {
        if(taxon_number == TRUE) {
            #Is it a valid number?
                if(taxon > length(data)) {
                stop("Taxon column not found in \"data\".")
            } else {
                taxon_col<-taxon
                taxon<-unique(as.vector(unlist(as.list(data[taxon]))))
            }                
        } else {
            #Is it a valid name?
            taxon_col<-grep(taxon, names(data))
            taxon<-unique(as.vector(unlist(as.list(data[taxon_col]))))
            check.class(taxon, 'character', " not found in \"data\".")
        }
    }


#FUNCTION

    #Cleaning a tree so that the species match with the ones in a table
    clean.tree.table<-function(tree, data, taxon, taxon_col) {

        #run comparative.data to check the non matching columns/rows
        missing_species<-comparative.data(tree, data.frame("species"=taxon, "dummy"=rnorm(length(taxon)), "dumb"=rnorm(length(taxon))), "species")$dropped

        #if non-matching tips, drop them
        if(length(missing_species$tips) != 0) {
            tree_tmp<-drop.tip(tree, missing_species$tips)
            dropped_tips<-missing_species$tips
        } else {
            tree_tmp<-tree
            dropped_tips<-NA
        }

        #if non-matching rows, drop them
        if(length(missing_species$unmatched.rows) != 0) {
            data_tmp<-data[-which(data[,taxon_col] == missing_species$unmatched.rows),]
            dropped_rows<-missing_species$unmatched.rows
        } else {
            data_tmp<-data
            dropped_rows<-NA
        }

        return(list("tree"=tree_tmp, "table"=data_tmp, "dropped_tips"=dropped_tips, "dropped_rows"=dropped_rows))
    }

#CLEANING THE DATA/TREES

    #for a single tree
    if(tree_class == "phylo") {
        cleaned_data<-clean.tree.table(tree, data, taxon, taxon_col)
    } else {
    #for multiple trees
        #lapply function
        lapply.clean<-function(X) {return(clean.tree.table(X, data, taxon, taxon_col))}
        cleaned_list<-lapply(tree, lapply.clean)

        #Selecting the tips to drop
        tips_to_drop<-NULL
        for(tr in 1:length(tree)) {
            tips_to_drop<-c(tips_to_drop, cleaned_list[[tr]]$dropped_tips)
        }

        #Selecting the rows to drop
        rows_to_drop<-NULL
        for(tr in 1:length(tree)) {
            rows_to_drop<-c(rows_to_drop, cleaned_list[[tr]]$dropped_rows)
        }

        #combining both
        taxa_to_drop<-c(tips_to_drop, rows_to_drop)
        #remove NAs
        taxa_to_drop<-taxa_to_drop[-which(is.na(taxa_to_drop))]

        #removing the rows from the data
        if(length(taxa_to_drop) != 0) {
            data_new<-data[-taxa_to_drop,]
            trees_new<-lapply(tree, drop.tip, tip=tips_to_drop) ; class(trees_new)<-'multiPhylo'
        } else {
            taxa_to_drop<-NA
            data_new<-data
            trees_new<-tree
        }

        #output list
        cleaned_data<-list("tree"=trees_new, "data"=data_new, "dropped.taxon"=taxa_to_drop)
    }

    return(cleaned_data)

#End
}